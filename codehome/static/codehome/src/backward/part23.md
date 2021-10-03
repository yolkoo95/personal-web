# Win32 Seg.2

## Table of Contents
- [Reverse](#reverse)
	- [WinMain](#winmain)
	- [ESP Addressing](#espaddressing)
	- [Debug Recall Function](#debugrecallfunction)
- [Child Window](#childwindow)
	- [Button](#button)
	- [WM_COMMAND](#wm_command)
- [Resources](#resources)
	- [Create Resource File](#createresourcefile)
	- [Create a Button](#createabutton)
	- [Login Demo](#logindemo)
	- [Assembly Analysis](#assemblyanalysis)
		- [Message Breakpoint](#messagebreakpoint)
		- [Memory Access Breakpoint](#memoryaccessbreakpoint)

<TableEndMark>

## Reverse

### WinMain

As we talked before, `WinMain` has the same function as `main`. It has following structure,

```c++
int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PWSTR pCmdLine, int nCmdShow);

// this is an empty WinMain
INT WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
    PSTR lpCmdLine, INT nCmdShow)
{
    return 0;
}
```

Now it's time to explore it from the point of reversing programming.

Look at the calling stack, we will find `WinMain` is not the entry point of the program at the level of assembly language, but a function called `WinMainCRTStartUp`.

```c++
WinMain(HINSTANCE__ * 0x00400000, HINSTANCE__ * 0x00000000, char * 0x00141f28, int 0x00000001) line 12
WinMainCRTStartup() line 198 + 54 bytes
KERNEL32! 7c816d4f()
```

Let's track back to `WinMainCRTStartUp` function to see what its assembly language looks like.

```c++
...
004016A4   mov         dword ptr [ebp-6Ch],0Ah
004016AB   mov         ecx,dword ptr [ebp-6Ch]
004016AE   push        ecx
004016AF   mov         edx,dword ptr [lpszCommandLine]
004016B2   push        edx
004016B3   push        0
004016B5   push        0
004016B7   call        dword ptr [__imp__GetModuleHandleA@4 (0042a1e4)]
004016BD   push        eax
004016BE   call        @ILT+10(_WinMain@16) (0040100f)
004016C3   mov         dword ptr [mainret],eax
...
```

Notice that WinMain is a function following `__stdcall`, so it has two main features:

- push arguments from right to left
- inner balance, `00401175   ret   10h`

Therefore, when reversing codes, we have to know some characteristics of the function, such as the number of parameters, calling conventions (the order of pushing arguments).

BTW, `GetModuleHandleA` is a non-input function.

### ESP Addressing

When we compile a program in debug version, it will take a method called EBP Addressing. However, in release version, the assembler will take ESP Addressing.

```c++
int plus(int a, int b) {
	return a + b;
}

int main(int argc, char* argv[])
{
	plus((int)1, (int)2);
	return 0;
}
```

```c++
// debug version:
// caller:
0040D708   push        2
0040D70A   push        1
0040D70C   call        @ILT+5(plus) (0040100a)
0040D711   add         esp,8
// callee:
00401010   push        ebp
00401011   mov         ebp,esp
00401013   sub         esp,40h
00401016   push        ebx
00401017   push        esi
00401018   push        edi
00401019   lea         edi,[ebp-40h]
0040101C   mov         ecx,10h
00401021   mov         eax,0CCCCCCCCh
00401026   rep stos    dword ptr [edi]
00401028   mov         eax,dword ptr [ebp+8]
0040102B   add         eax,dword ptr [ebp+0Ch]
0040102E   pop         edi
0040102F   pop         esi
00401030   pop         ebx
00401031   mov         esp,ebp
00401033   pop         ebp
00401034   ret
```

EBP Addressing:
PRO: stable address in each segment, since `ebp` is fixed.
CON: relatively complicated operation, for example elevate stack.

```c++
// release version:
// caller:
00401010  6A 02         PUSH 2
00401012  6A 01         PUSH 1
00401014  E8 E7FFFFFF   CALL zzzz.00401000
00401019  83C4 08       ADD ESP,8
0040101C  33C0          XOR EAX,EAX
0040101E  C3            RETN
// callee:
00401000  8B4424 08     MOV EAX,DWORD PTR SS:[ESP+8]
00401004  8B4C24 04     MOV ECX,DWORD PTR SS:[ESP+4]
00401008  03C1          ADD EAX,ECX
0040100A  C3            RETN

// memory:
0012FF78   00401019  // ESP: RETURN to zzzz.00401019 from zzzz.00401000
0012FF7C   00000001
0012FF80   00000002
```

ESP Addressing:
PRO: simplified operation.
CON: addresses are various with `esp`.

Often, functions with `esp addressing` start with `sub esp, n`. If we are in the first instruction of a child function, then `esp` points to the recall address, `esp + 4n` points to the *n*th parameter of the function.

### Debug Recall Function

Recall function here refers to `WindowProc()`.

```c++
LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
```

Now the question is how we are able to locate recall function? There is only one clue -- `WindowProc()` is called by `DispatchMessage()`.

The key is the structure of `WNDCLASS` and conditional breakpoint.

```c++
typedef struct _WNDCLASS { 
    UINT       style; 
    WNDPROC    lpfnWndProc; 
    int        cbClsExtra; 
    int        cbWndExtra; 
    HINSTANCE  hInstance; 
    HICON      hIcon; 
    HCURSOR    hCursor; 
    HBRUSH     hbrBackground; 
    LPCTSTR    lpszMenuName; 
    LPCTSTR    lpszClassName; 
} WNDCLASS, *PWNDCLASS; 
```

We are able to find the address of `WindowProc()` in the second member of `WNDCLASS`, which is `lpfnWndProc`. Given that the parameter of `RegisterClass()` is a pointer to a WNDCLASS struct, so this is the crux.

![RegisterClass](codehome/src/img/backward/winapp-01.png)

![Pointer to WndProc](codehome/src/img/backward/winapp-02.png)

![Conditional Breakpoint](codehome/src/img/backward/winapp-03.png)

Notice that `esp + 8` must be `uMsg`, since it's the second parameter of `WindowProc()`.

There is a ascii table to refer in the 

![ASCII](codehome/src/img/backward/ascii-web.png)

## Child Window

Despite init window, there are many windows attached with init window, such as button, checkbox, and so on.

### Button

We will take button as example.

```c++
// the normal steps for creating a window
// as shown in previous example.
1. Customize Window Class.
2. Register Class.
3. Create Window.
4. Message Loop.
5. Customize Message Process Function.
```

However, `BUTTON CLASS` is a builtin class of windows. Therefore, we do NOT have to customize class, register class and write message loop.

```c++
HINSTANCE hAppInstance;  // app handle, often used

void CreateButton(HWND hwnd) {
    HWND hwndPushButton = CreateWindow ( 	
	TEXT("button"),  
	TEXT("normal button"),
	//WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON | BS_DEFPUSHBUTTON,
	WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON | BS_DEFPUSHBUTTON,
	10, 10,
	80, 20,
	hwnd,       // handle of parent
	(HMENU)1001,    // unique id of child window
	hAppInstance, 
	NULL);
}

int APIENTRY WinMain(HINSTANCE hInstance,
                     HINSTANCE hPrevInstance,
                     LPSTR     lpCmdLine,
                     int       nCmdShow)
{
	hAppInstance = hInstance; // get app handle
    ...

    if (hwnd == NULL)
	{
		return 0;
	}

	CreateButton(hwnd);

	ShowWindow(hwnd, nCmdShow);
    ...
```

The output of program is as follows,

![Create Button](codehome/src/img/backward/button-01.png)

### WM_COMMAND

After creating a button, now it's time to configure `WindowProc()`.

What's the relationship between process functions of child and parent.

```c++
Button ----> WinProc() // system 
 // button msg
       ----> WinProc() // parent
 // WM_COMMAND
```

Notice that the system will call process function of system first, and then, at some time, it will call process function of parent, which includes process of child function in `WM_COMMAND` case.

In order to locate parent `WinProc()`, we have to index system `WinProc()`. To find the address of `WinProc()`, we must know the structure of `button`, a builtin class.

```c++
// two useful api for querying class info
TCHAR szBuffer[0x20];				
GetClassName(hwndPushButton, szBuffer, 0x20);	

WNDCLASS bt;					
GetClassInfo(hAppInstance, szBuffer, &bt);					
OutputDebugStringF("-->%s\n", bt.lpszClassName);					
OutputDebugStringF("-->%x\n", bt.lpfnWndProc);					
```

```c++
case WM_COMMAND:	
{	
	switch(LOWORD(wParam))
	{
        case 1001: 
            MessageBox(hwnd, "Hello Button", "Demo", MB_OK);
	
	
	}
	return DefWindowProc(hwnd,uMsg,wParam,lParam);
}	
```

When click button,

![Button Demo](codehome/src/img/backward/button-02.png)


## Resources

### Create Resource File

Create a resource file with following steps in vc++6.0:

1. click file, and new file.
2. choose resource script.
3. include `resource.h` to the project.

### Create a Button

Creating a button with resource file is sort of like with MFC.

1. open resource file.
2. insert components.
3. configure components.

![Button Demo2](codehome/src/img/backward/button-03.png)

After building program, we will find resource script help us with configuring setting of app components.

```c++
// resource.h
// Microsoft Developer Studio generated include file.
// Used by src.rc
//
#define IDD_MAIN_DIALOGUE               101
#define IDC_BUTTON_YES                  1000
```

```c++
// the normal steps for creating a window
// as shown in previous example.
1. Customize Window Class.
2. Register Class.
3. Create Window.
4. Message Loop.
5. Customize Message Process Function.
```

Yet with resource script, we only have to create window and set message process function, since other steps are managed by script.

We are able to create dialog box with builtin api `DialogBox()`.

```c++
INT_PTR DialogBox(
  HINSTANCE hInstance,  // handle to module
  LPCTSTR lpTemplate,   // dialog box template
  HWND hWndParent,      // handle to owner window
  DLGPROC lpDialogFunc  // dialog box procedure
);
```

For the second member of DialogBox, it can be a name or component id, which is sort of like import directory whose function can be indexed by function name or ordinal. 

TIP: if locating component by id, we have to transfer id (say a integer value) from `int` to a string as explained in MSDN with macro `MAKEINTRESOURCE`.

```c++
BOOL CALLBACK DialogProc(HWND hwndDlg, UINT uMsg, WPARAM wParam, LPARAM lParam);

int APIENTRY WinMain(HINSTANCE hInstance,
                     HINSTANCE hPrevInstance,
                     LPSTR     lpCmdLine,
                     int       nCmdShow)
{
 	// TODO: Place code here.
	DialogBox(hInstance, MAKEINTRESOURCE(IDD_MAIN_DIALOGUE), NULL, DialogProc);

	return 0;
}

BOOL CALLBACK DialogProc(HWND hwndDlg,
						 UINT uMsg,
						 WPARAM wParam,
						 LPARAM lParam)
{
	return TRUE;
}
```

One thing worth noticing is that in `DialogProc()`, if the message has been handled then return TRUE, if not, return FALSE, which is slight different from previous windows.

### Login Demo

Now we are able to make a simple login dialog with resource script.

![Login Demo](codehome/src/img/backward/demo-01.png)

```c++
// process function:
BOOL CALLBACK DialogProc(HWND hwndDlg,
						 UINT uMsg,
						 WPARAM wParam,
						 LPARAM lParam)
{
	switch(uMsg) 
	{				

	case WM_INITDIALOG:						
	//	MessageBox(NULL,TEXT("WM_INITDIALOG"),TEXT("INIT"),MB_OK);			
		return TRUE;			
				
	case WM_COMMAND:				
		
		switch (LOWORD(wParam))			
		{			
		case IDC_BUTTON_OK:				
			MessageBox(NULL,TEXT("IDC_BUTTON_OK"),TEXT("OK"),MB_OK);
			
			return TRUE;		
		case IDC_BUTTON_EXIT:			
			MessageBox(NULL,TEXT("See u next time"),TEXT("EXIT"),MB_OK);		
			EndDialog(hwndDlg, 0);		

			return TRUE;		
		}
		
	break;
	}

	return FALSE;
}
```

The question is how to get content of edit text box.

```c++
// get handle of text box
hEditName = GetDlgItem(hwndDlg, IDC_EDIT_USERNAME);
hEditPasswd = GetDlgItem(hwndDlg, IDC_EDIT_PASSWD);

// get the content of text box
TCHAR nameBuffer[0x20]
TCHAR passwdBuffer[0x20]
GetWindowText(hEditName, nameBuffer, 0x20);
GetWindowText(hEditPasswd, passwdBuffer, 0x20);
```

Finally, the finished version is as follows,

```c++
BOOL CALLBACK DialogProc(HWND hwndDlg,
						 UINT uMsg,
						 WPARAM wParam,
						 LPARAM lParam)
{	
	HWND hEditName = NULL;
	HWND hEditPasswd = NULL;
	switch(uMsg) 
	{				

	case WM_INITDIALOG:				
	//	MessageBox(NULL,TEXT("WM_INITDIALOG"),TEXT("INIT"),MB_OK);			
		return TRUE;			
				
	case WM_COMMAND:				
		
		switch (LOWORD(wParam))			
		{			
		case IDC_BUTTON_OK:				
			// get handle of text box
			hEditName = GetDlgItem(hwndDlg, IDC_EDIT_USERNAME);
			hEditPasswd = GetDlgItem(hwndDlg, IDC_EDIT_PASSWD);

			// get the content of text box
			TCHAR nameBuffer[0x20];
			TCHAR passwdBuffer[0x20];
			GetWindowText(hEditName, nameBuffer, 0x20);
			GetWindowText(hEditPasswd, passwdBuffer, 0x20);

			MessageBox(NULL,TEXT(nameBuffer),TEXT("OK"),MB_OK);
			
			return TRUE;		
		case IDC_BUTTON_EXIT:			
			MessageBox(NULL,TEXT("See u next time"),TEXT("EXIT"),MB_OK);		
			EndDialog(hwndDlg, 0);		

			return TRUE;		
		}
		
	break;
	}

	return FALSE;
}
```

![Login Demo Output](codehome/src/img/backward/demo-02.png)

### Assembly Analysis

There are two breakpoints worth talking about -- message breakpoint and memory access breakpoint.

#### Message Breakpoint

As known before, user-customized process function is called by one of system process functions at some time. We are able to locate system process functions by debug tools as follows,

![System Process Functions](codehome/src/img/backward/msgbp-01.png)

Then set a message breakpoint to `button`.

```c++
// event --> system process --> customized process
//  WM_LBUTTONUP        WM_COMMAND 
```

Hence, we have to set breakpoint of `WM_LBUTTONUP` rather than `WM_COMMAND`.

Then we are in system process function, but how to find our process function? The trick is resorting to memory access breakpoint.

#### Memory Access Breakpoint

As we know, our function is compiled into memory with starting address of `0x4000000` in general. So we are able to set memory breakpoint at `.text` segment, aka. code segment.

Click `ok` button, then the process will stop on the first instruction of system process.

![Message Breakpoint](codehome/src/img/backward/msgbp-02.png)

IMPORTANT: we have to check if the message is what we want by looking at stack. Notice that `esp+8` is 202, well done.

Then set memory access breakpoint.

![Memory Access Breakpoint](codehome/src/img/backward/msgbp-03.png)

Continue the program,

![Pitfall](codehome/src/img/backward/msgbp-04.png)

Now we are in our process function, but after checking memory stack, we will find msg code is `0x135`, `WM_CTLCOLORBTN`, not what we want, `0x11`, `WM_COMMAND`.

What to do then?

1. single step with `F8` until going into memory space of system functions.
2. click `F9` to continue program until next memory breakpoint. 

```c++
// event --> system process --> customized process
//  WM_LBUTTONUP        WM_CTLCOLORBTN   ..F8..
//		   		..F9..	WM_COMMAND 
//                      ...
```

IMPORTANT: Notice that even if we click left button, the system process function will call our customized function by other message such as `WM_CTLCOLORBTN`, we have to continue the program until the call is triggered by `WM_COMMAND`.

Experiment tells us after `WM_CTLCOLORBTN` is `WM_COMMAND`, which is `0x111`.

![WM_COMMAND](codehome/src/img/backward/msgbp-05.png)

<EndMarkdown>