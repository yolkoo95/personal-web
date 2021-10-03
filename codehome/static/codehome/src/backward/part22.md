# Win32 Seg.1

## Table of Contents

- [Code Standard](#codestandard)
    - [ASCII](#ascii)
    - [GB2312](#gb2312)
    - [Unicode](#unicode)
- [Wide Char](#widechar)
- [Win32 API](#win32api)
    - [TChar](#tchar)
- [Win32 Main](#win32main)
- [Win32 Debug](#win32debug)
- [Program](#program)
    - [Create a Window](#createawindow)
    - [Window Messages](#windowmessages)
    - [Window Procedure](#windowprocedure)
    - [Painting](#painting)
    - [Closing the Window](#closingthewindow)

<TableEndMark>

## Code Standard

As we all know, computer stores symbols as binary form. The question is how many mapping a symbol has? To solve that problem, we have to discuss coding standard.

### ASCII

ASCII, abbreviated from American Standard Code for Information Interchange, is a character encoding standard for electronic communication. ASCII codes represent text in computers, telecommunications equipment, and other devices. Most modern character-encoding schemes are based on ASCII, although they support many additional characters.

For standard ASCII, it takes 7 bits, ranging from 0 ~ 128. In memory, it takes 1 byte block. For example, `65` (`0x41` or `0x01000001`) for `A`.

![Standard ASCII Table](codehome/src/img/backward/ascii-table.png)

To store more symbols, programmers take use of the most significant bit, ranging from 128 ~ 255, which is called ANSI encoding. For example, `128` (`0x80` or `0x10000000`) for `?`.

![Extended ASCII Table](codehome/src/img/backward/ascii-table-extended.png)

ANSI encoding is a slightly generic term used to refer to the standard code page on a system, usually Windows. It is more properly referred to as Windows-1252 on Western/U.S. systems. (It can represent certain other Windows code pages on other systems.) This is essentially an extension of the ASCII character set in that it includes all the ASCII characters with an additional 128 character codes. This difference is due to the fact that "ANSI" encoding is 8-bit rather than 7-bit as ASCII is (ASCII is almost always encoded nowadays as 8-bit bytes with the MSB set to 0).

### GB2312

To code Chinese symbols, Chinese genius designed code standard called GB2312, which is based on ASCII. It use 2 bytes to save a Chinese symbol, each of which takes 1 as the most significant bit. In other words, it takes two extended ascii code and combines them to save a Chinese symbol.

For example, `B0A1` for `啊`, `B0A2` for `阿`.

### Unicode

Many programers, however, from different countries will conflict with each other in designing code standard for their mother languages. Each symbol takes 2 bytes. For example, `B0A1` for `啊` in Chinese, however for `こん` in Japanese.

To solve that problem, experts from all over the world discuss and design a general code standard called unicode. Since unicode only includes Chinese symbols that is frequently used, we are not able to output some less-frequent words with unicode.

BTW, `utf-8` is a variant of unicode. It takes 1 or 2 bytes for each symbol according to the frequency of symbol to be used.

## Wide Char

With the background of code standard, now we will discuss wide char.

Notice that `中` in ASCII is `0xD6D0`, and in unicode is `0x4E2D`. 

```c++
char ch = '中';
// D0 FF EF FF  only get one byte
wchar_t ch_ascii = '中';
// D0 D6 00 FF  use ascii code, end with 00
wchar_t ch_unicode = L'中';
// 2D 4E 00 00 FF  use unicode, end with 00 00
```

`wchar_t` is what we call wide character. Different from `char`, it takes 2 bytes of memory.

How to print `wchar_t` with unicode?

```c++
#include <locale.h>

setlocale(LC_ALL, ""); // set location
wprintf(L"%s\n", ch_unicode);

// strlen of wide char
printf("the length of string: %d\n", wcslen(ch_unicode));
// output: 1

// strcpy of wide char
wchar_t s[] = L"中国";
wchar_t s1[] = L"你好";
wcscpy(s, s1);
```

## Win32 API

The Windows API, informally WinAPI, is Microsoft's core set of application programming interfaces (APIs) available in the Microsoft Windows operating systems.

Most of api is saved in `*.dll` files under `C:\WINDOWS\system32\` for 32-bit system, such as `Kernel32.dll`, `User32.dll`, `GDI32.dll`.

### TChar

Back when applications needed to support both Windows NT as well as Windows 95, Windows 98, and Windows Me, it was useful to compile the same code for either ANSI or Unicode strings, depending on the target platform. To this end, the Windows SDK provides macros that map strings to Unicode or ANSI, depending on the platform.

| Macro | Unicode | ANSI |
| :---: | :---: | :---: |
| TCHAR | wchar_t | char |
| TEXT("x") | L"x" | "x" |

```c++
char           CHAR
wchar_t        WCHAR
[macro name]   TCHAR
```

```c++
// whether it is coded with ascii or unicode is
// decided by system settings.
TCHAR cht[] = TEXT("中国");
PTSTR str_t = TEXT("中国");
```

There are two kinds of api for users, one for ascii and the other for unicode. For example, `MessageBoxA` and `MessageBoxW`, and `MessageBox` is just a macro name.

```c++
int main(int argc, char* argv[]) {
    MessageBox(0, 0, 0, 0);

    return 0;
}

// find the declaration of MessageBox
MessageBoxW(
    HWND hWnd ,
    LPCWSTR lpText,
    LPCWSTR lpCaption,
    UINT uType);
#ifdef UNICODE
#define MessageBox  MessageBoxW
#else
#define MessageBox  MessageBoxA
#endif // !UNICODE
```

Internally, the ANSI version translates the string to Unicode. The Windows headers also define a macro that resolves to the Unicode version when the preprocessor symbol `UNICODE` is defined or the ANSI version otherwise.

New applications should always call the Unicode versions. Many world languages require Unicode. If you use ANSI strings, it will be impossible to localize your application. The ANSI versions are also less efficient, because the operating system must convert the ANSI strings to Unicode at run time. Depending on your preference, you can call the Unicode functions explicitly, such as SetWindowTextW, or use the macros. The example code on MSDN typically calls the macros, but the two forms are exactly equivalent. Most newer APIs in Windows have just a Unicode version, with no corresponding ANSI version.

## Win32 Main

`WinMain` is sort of like `main` in console application. Every Windows program includes an entry-point function that is named either WinMain or wWinMain. Here is the signature for wWinMain.

```c++
int APIENTRY WinMain(HINSTANCE hInstance,
                     HINSTANCE hPrevInstance,
                     LPSTR     lpCmdLine,
                     int       nCmdShow)
{
 	// TODO: Place code here.

	return 0;
}
```

The four parameters are:

- `hInstance` is something called a "handle to an instance" or "handle to a module." The operating system uses this value to identify the executable (EXE) when it is loaded in memory. The instance handle is needed for certain Windows functions —- for example, to load icons or bitmaps.
- `hPrevInstance` has no meaning. It was used in 16-bit Windows, but is now always zero.
- `pCmdLine` contains the command-line arguments as a Unicode string.
- `nCmdShow` is a flag that says whether the main application window will be minimized, maximized, or shown normally.

The function returns an int value. The return value is not used by the operating system, but you can use the return value to convey a status code to some other program that you write.

WINAPI is the calling convention. A calling convention defines how a function receives parameters from the caller. For example, it defines the order that parameters appear on the stack. 

```c++
#define WINAPI __stdcall
```

## Win32 Debug

There is a trick for debug in win32 application.

```c++
// tools.h
void __cdecl OutputDebugStringF(const char *format, ...); 

// this is a trick for debug
#ifdef _DEBUG  
#define DbgPrintf   OutputDebugStringF  
#else  
#define DbgPrintf  
#endif 
```

```c++
// tools.cpp
void __cdecl OutputDebugStringF(const char *format, ...)  
{  
    va_list vlArgs;  
    char    *strBuffer = (char*)GlobalAlloc(GPTR, 4096);  

    va_start(vlArgs, format);  
    _vsnprintf(strBuffer, 4096 - 1, format, vlArgs);  
    va_end(vlArgs);  
    strcat(strBuffer, "\n");  
    OutputDebugStringA(strBuffer);  
    GlobalFree(strBuffer);  
    return;  
}  
```

```c++
// main.cpp:
#include "stdafx.h" // which include <stdio.h> and <windows.h>
#include "tools.h"

int APIENTRY WinMain(HINSTANCE hInstance,
                     HINSTANCE hPrevInstance,
                     LPSTR     lpCmdLine,
                     int       nCmdShow)
{	
	DbgPrintf("Hello %s!\n", "Win32");

	return 0;
} 
```

- `GetLastError`
The `GetLastError` function retrieves the calling thread's last-error code value.

```c++
DWORD err_code = GetLastError();
```

## Program

Before starting to program, we will abbreviate how a win32 application works as follows,

```bash
an event --> a message --> system queue --> application queue
--> func: GetMessage() --> func: DispatchMessage() --> system operations 
--> call WindowProc() 
```

![Message Flow](codehome/src/img/backward/message-flow.png)

### Create a Window

A window class defines a set of behaviors that several windows might have in common. For example, in a group of buttons, each button has a similar behavior when the user clicks the button. Of course, buttons are not completely identical; each button displays its own text string and has its own screen coordinates. Data that is unique for each window is called instance data.

Every window must be associated with a window class, even if your program only ever creates one instance of that class. It is important to understand that a window class is not a "class" in the C++ sense. Rather, it is a data structure used internally by the operating system. Window classes are registered with the system at run time. To register a new window class, start by filling in a WNDCLASS structure:

```c++
// Register the window class.
// design class style of window
TCHAR CLASS_NAME[]  = L"Sample Window Class";

WNDCLASS wc = {0};
wc.lpfnWndProc = WindowProc;
wc.hInstance = hInstance;
wc.lpszClassName = CLASS_NAME;
```

You must set the following structure members:

- `lpfnWndProc` is a pointer to an application-defined function called the window procedure or "window proc." The window procedure defines most of the behavior of the window. We'll examine the window procedure in detail later. For now, just treat this as a forward reference.
- `hInstance` is the handle to the application instance. Get this value from the hInstance parameter of wWinMain.
- `lpszClassName` is a string that identifies the window class.

Class names are local to the current process, so the name only needs to be unique within the process. However, the standard Windows controls also have classes. If you use any of those controls, you must pick class names that do not conflict with the control class names. For example, the window class for the button control is named "Button".

Next, pass the address of the WNDCLASS structure to the RegisterClass function. This function registers the window class with the operating system.

```c++
RegisterClass(&wc);
```

To create a new instance of a window, call the `CreateWindowEx` function:

```c++
HWND hwnd = CreateWindowEx(
    0,			// Extended window style
    CLASS_NAME,                     // Window class
    TEXT("Learn to Program Windows"),    // Window text
    WS_OVERLAPPEDWINDOW,            // Window style

    // Size and position
    CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,

    NULL,       // Parent window    
    NULL,       // Menu
    hInstance,  // Instance handle
    NULL        // Additional application data
    );

if (hwnd == NULL)
{
    return 0;
}
```

You can read detailed parameter descriptions on MSDN, but here is a quick summary:

- The first parameter lets you specify some optional behaviors for the window (for example, transparent windows). Set this parameter to zero for the default behaviors.
- `CLASS_NAME` is the name of the window class. This defines the type of window you are creating.
- The window text is used in different ways by different types of windows. If the window has a title bar, the text is displayed in the title bar.
- The window style is a set of flags that define some of the look and feel of a window. The constant `WS_OVERLAPPEDWINDOW` is actually several flags combined with a bitwise OR. Together these flags give the window a title bar, a border, a system menu, and Minimize and Maximize buttons. This set of flags is the most common style for a top-level application window.
- For position and size, the constant `CW_USEDEFAULT` means to use default values.
- The next parameter sets a parent window or owner window for the new window. Set the parent if you are creating a child window. For a top-level window, set this to NULL.
- For an application window, the next parameter defines the menu for the window. This example does not use a menu, so the value is NULL.
- `hInstance` is the instance handle, described previously. 
- The last parameter is a pointer to arbitrary data of type void*. You can use this value to pass a data structure to your window procedure. 

`CreateWindowEx` returns a handle to the new window, or zero if the function fails. To show the window—that is, make the window visible —- pass the window handle to the ShowWindow function:

```c++
ShowWindow(hwnd, nCmdShow);
```

The `hwnd` parameter is the window handle returned by CreateWindowEx. The `nCmdShow` parameter can be used to minimize or maximize a window. The operating system passes this value to the program through the `WinMain` function.

Here is the complete code to create the window. Remember that WindowProc is still just a forward declaration of a function.

```c++
#include "stdafx.h"

LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);

int APIENTRY WinMain(HINSTANCE hInstance,
                     HINSTANCE hPrevInstance,
                     LPSTR     lpCmdLine,
                     int       nCmdShow)
{
	// Register the window class.s
 	TCHAR CLASS_NAME[]  = "Sample Window Class";

	WNDCLASS wc = {0};
	wc.lpfnWndProc = WindowProc;
	wc.hInstance = hInstance;
	wc.lpszClassName = CLASS_NAME;

	RegisterClass(&wc);

	// Create the window.
	HWND hwnd = CreateWindowEx(
        0,			// Extended window style
		CLASS_NAME,                     // Window class
		TEXT("Learn to Program Windows"),    // Window text
		WS_OVERLAPPEDWINDOW,            // Window style

		// Size and position
		CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,

		NULL,       // Parent window    
		NULL,       // Menu
		hInstance,  // Instance handle
		NULL        // Additional application data
    );

	if (hwnd == NULL)
	{
		return 0;
	}

	ShowWindow(hwnd, nCmdShow);
	
	// message loop: we we discuss later
	MSG msg;
	while (GetMessage(&msg, NULL, 0, 0)) {
		TranslateMessage(&msg);
		DispatchMessage(&msg);
	}

	return 0;
} 

LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
	
	return DefWindowProc(hwnd, uMsg, wParam, lParam);
}
```

### Window Messages

A GUI application must respond to events from the user and from the operating system.

- Events from the user include all the ways that someone can interact with your program: mouse clicks, key strokes, touch-screen gestures, and so on.
- Events from the operating system include anything "outside" of the program that can affect how the program behaves. For example, the user might plug in a new hardware device, or Windows might enter a lower-power state (sleep or hibernate).

These events can occur at any time while the program is running, in almost any order. How do you structure a program whose flow of execution cannot be predicted in advance?

To solve this problem, Windows uses a message-passing model. The operating system communicates with your application window by passing messages to it. A message is simply a numeric code that designates a particular event. For example, if the user presses the left mouse button, the window receives a message that has the following message code.

```c++
define WM_LBUTTONDOWN    0x0201
```

Some messages have data associated with them. For example, the `WM_LBUTTONDOWN` message includes the x-coordinate and y-coordinate of the mouse cursor.

To pass a message to a window, the operating system calls the window procedure registered for that window.

##### The Message Loop

An application will receive thousands of messages while it runs. (Consider that every keystroke and mouse-button click generates a message.) Additionally, an application can have several windows, each with its own window procedure. How does the program receive all these messages and deliver them to the correct window procedure? The application needs a loop to *retrieve the messages and dispatch them* to the correct windows.

For each thread that creates a window, the operating system creates a queue for window messages. This queue holds messages for all the windows that are created on that thread. The queue itself is hidden from your program (As shown before). You cannot manipulate the queue directly. However, you can pull a message from the queue by calling the `GetMessage` function.

```c++
MSG msg;
GetMessage(&msg, NULL, 0, 0);
```

This function removes the first message from the head of the queue. If the queue is empty, the function blocks until another message is queued. The fact that `GetMessage` blocks will not make your program unresponsive. If there are no messages, there is nothing for the program to do. If you have to perform background processing, you can create additional threads that continue to run while GetMessage waits for another message. 

The first parameter of `GetMessage` is the address of a `MSG` structure. If the function succeeds, it fills in the MSG structure with information about the message. This includes the target window and the message code. The other three parameters let you filter which messages you get from the queue. In almost all cases, you will set these parameters to zero.

Although the MSG structure contains information about the message, you will almost never examine this structure directly. Instead, you will pass it directly to two other functions.

```c++
TranslateMessage(&msg); 
DispatchMessage(&msg);
```

The `TranslateMessage` function is related to keyboard input. It translates keystrokes (key down, key up) into characters. You do not really have to know how this function works; just remember to call it before `DispatchMessage`. 

The `DispatchMessage` function tells the operating system to call the window procedure of the window that is the target of the message. In other words, the operating system looks up the window handle in its table of windows, finds the function pointer associated with the window, and invokes the function.

For example, suppose that the user presses the left mouse button. This causes a chain of events:

1. The operating system puts a `WM_LBUTTONDOWN` message on the message queue.
2. Your program calls the `GetMessage` function.
3. `GetMessage` pulls the `WM_LBUTTONDOWN` message from the queue and fills in the `MSG` structure.
4. Your program calls the `TranslateMessage` and `DispatchMessage` functions.
5. Inside `DispatchMessage`, the operating system calls your window procedure.
6. Your window procedure can either respond to the message or ignore it (relay it to the system function `DefWindowProc()`).

When the window procedure returns, it returns back to `DispatchMessage`. This returns to the message loop for the next message. As long as your program is running, messages will continue to arrive on the queue. Therefore, you must have a loop that continually pulls messages from the queue and dispatches them. You can think of the loop as doing the following:

```c++
// WARNING: Don't actually write your loop this way.
while (1)      
{
    GetMessage(&msg, NULL, 0,  0);
    TranslateMessage(&msg); 
    DispatchMessage(&msg);
}
```

As written, of course, this loop would never end. That is where the return value for the `GetMessage` function comes in. Normally, `GetMessage` returns a nonzero value. When you want to exit the application and break out of the message loop, call the `PostQuitMessage` function.

```c++
PostQuitMessage(0);
```

The `PostQuitMessage` function puts a `WM_QUIT` message on the message queue. `WM_QUIT` is a special message: It causes `GetMessage` to return zero, signaling the end of the message loop. Here is the revised message loop.

```c++
// Correct
MSG msg = { };
while (GetMessage(&msg, NULL, 0, 0) > 0)
{
    TranslateMessage(&msg);
    DispatchMessage(&msg);
}
```

As long as `GetMessage` returns a nonzero value, the expression in the while loop evaluates to `true`. After you call `PostQuitMessage`, the expression becomes false and the program breaks out of the loop. (One interesting result of this behavior is that your window procedure never receives a `WM_QUIT` message. Therefore, you do not have to have a case statement for this message in your window procedure.)

The next obvious question is when to call `PostQuitMessage`. We'll return to this question in the topic *Closing the Window*, but first we have to write our window procedure.

##### Post versus Send

The previous section talked about messages going onto a queue. Sometimes, the operating system will call a window procedure directly, bypassing the queue.

The terminology for this distinction can be confusing:

- *Posting a message* means the message goes on the message queue, and is dispatched through the message loop (`GetMessage` and `DispatchMessage`).
- *Sending a message* means the message skips the queue, and the operating system calls the window procedure directly.

For now, the difference is not very important. The window procedure handles all messages. However, some messages bypass the queue and go directly to your window procedure. However, it can make a difference if your application communicates between windows.

### Window Procedure

##### User Procedure

The `DispatchMessage` function calls the window procedure of the window that is the target of the message. The window procedure has the following signature.

```c++
LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
```

There are four parameters:

- `hwnd` is a handle to the window.
- `uMsg` is the message code; for example, the `WM_SIZE` message indicates the window was resized.
- `wParam` and `lParam` contain additional data that pertains to the message. The exact meaning depends on the message code.

`LRESULT` is an integer value that your program returns to Windows. It contains your program's response to a particular message. The meaning of this value depends on the message code. `CALLBACK` is the calling convention for the function.

A typical window procedure is simply a large switch statement that switches on the message code. Add cases for each message that you want to handle.

```c++
switch (uMsg)
{
    case WM_SIZE: // Handle window resizing

    // etc
}
```

Additional data for the message is contained in the lParam and wParam parameters. Both parameters are integer values the size of a pointer width (32 bits or 64 bits). The meaning of each depends on the message code (`uMsg`). For each message, you will need to look up the message code on MSDN and cast the parameters to the correct data type. Usually the data is either a numeric value or a pointer to a structure. Some messages do not have any data.

For example, the documentation for the `WM_SIZE` message states that:

- `wParam` is a flag that indicates whether the window was minimized, maximized, or resized.
- `lParam` contains the new width and height of the window as 16-bit values packed into one 32- or 64-bit number. You will need to perform some bit-shifting to get these values. Fortunately, the header file `WinDef.h` includes helper macros that do this.

A typical window procedure handles dozens of messages, so it can grow quite long. One way to make your code more modular is to put the logic for handling each message in a separate function. In the window procedure, cast the `wParam` and `lParam` parameters to the correct data type, and pass those values to the function. For example, to handle the WM_SIZE message, the window procedure would look like this:

```c++
LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    switch (uMsg)
    {
    case WM_SIZE:
        {
            int width = LOWORD(lParam);  // Macro to get the low-order word.
            int height = HIWORD(lParam); // Macro to get the high-order word.

            // Respond to the message:
            OnSize(hwnd, (UINT)wParam, width, height);
        }
        break;
    }
}

void OnSize(HWND hwnd, UINT flag, int width, int height)
{
    // Handle resizing
}
```

The `LOWORD` and `HIWORD` macros get the 16-bit width and height values from lParam. (You can look up these kinds of details in the MSDN documentation for each message code.) The window procedure extracts the width and height, and then passes these values to the `OnSize` function.

##### Default Message Handling

If you don't handle a particular message in your window procedure, pass the message parameters directly to the `DefWindowProc` function. This function performs the default action for the message, which varies by message type.

```c++
return DefWindowProc(hwnd, uMsg, wParam, lParam);
```

TIPS: 
Avoiding Bottlenecks in Your Window Procedure: While your window procedure executes, it blocks any other messages for windows created on the same thread. Therefore, avoid lengthy processing inside your window procedure. For example, suppose your program opens a TCP connection and waits indefinitely for the server to respond. If you do that inside the window procedure, your UI will not respond until the request completes. During that time, the window cannot process mouse or keyboard input, repaint itself, or even close.

Instead, you should move the work to another thread, using one of the multitasking facilities that are built into Windows:

- Create a new thread.
- Use a thread pool.
- Use asynchronous I/O calls.
- Use asynchronous procedure calls.

### Painting

You've created your window. Now you want to show something inside it. In Windows terminology, this is called painting the window. To mix metaphors, a window is a blank canvas, waiting for you to fill it.

Sometimes your program will initiate painting to update the appearance of the window. At other times, the operating system will notify you that you must repaint a portion of the window. When this occurs, the operating system sends the window a `WM_PAINT` message. The portion of the window that must be painted is called the *update region*.

The first time a window is shown, the entire client area of the window must be painted. Therefore, you will always receive at least one `WM_PAINT` message when you show a window.

![Client Area](codehome/src/img/backward/painting-01.png)

You are only responsible for painting the client area. The surrounding frame, including the title bar, is automatically painted by the operating system. After you finish painting the client area, you clear the update region, which tells the operating system that it does not need to send another `WM_PAINT` message until something changes.

Now suppose the user moves another window so that it obscures a portion of your window. When the obscured portion becomes visible again, that portion is added to the update region, and your window receives another `WM_PAINT` message.

![Update Region](codehome/src/img/backward/painting-02.png)

The update region also changes if the user stretches the window. In the following diagram, the user stretches the window to the right. The newly exposed area on the right side of the window is added to the update region:

![Stretch](codehome/src/img/backward/painting-03.png)

In our first example program, the painting routine is very simple. It just fills the entire client area with a solid color. Still, this example is enough to demonstrate some of the important concepts.

```c++
switch (uMsg)
{
    case WM_PAINT:
    {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hwnd, &ps);

        // All painting occurs here, between BeginPaint and EndPaint.

        FillRect(hdc, &ps.rcPaint, (HBRUSH) (COLOR_WINDOW+1));

        EndPaint(hwnd, &ps);
    }
    return 0;
}
```

Start the painting operation by calling the BeginPaint function. This function fills in the `PAINTSTRUCT `structure with information on the repaint request. The current update region is given in the `rcPaint` member of `PAINTSTRUCT`. This update region is defined relative to the client area:

![Location](codehome/src/img/backward/painting-04.png)

In your painting code, you have two basic options:

- Paint the entire client area, regardless of the size of the update region. Anything that falls outside of the update region is clipped. That is, the operating system ignores it.
- Optimize by painting just the portion of the window inside the update region.

If you always paint the entire client area, the code will be simpler. If you have complicated painting logic, however, it can be more efficient to skip the areas outside of the update region.

The following line of code fills the update region with a single color, using the system-defined window background color (`COLOR_WINDOW`). The actual color indicated by `COLOR_WINDOW` depends on the user's current color scheme.

```c++
FillRect(hdc, &ps.rcPaint, (HBRUSH) (COLOR_WINDOW+1));
```

The details of `FillRect` are not important for this example, but the second parameter gives the coordinates of the rectangle to fill. In this case, we pass in the entire update region (the `rcPaint` member of `PAINTSTRUCT`). On the first WM_PAINT message, the entire client area needs to be painted, so `rcPaint` will contain the entire client area. On subsequent WM_PAINT messages, `rcPaint` might contain a smaller rectangle.

After you are done painting, call the `EndPaint` function. This function clears the update region, which signals to Windows that the window has completed painting itself.

### Closing the Window

When the user closes a window, that action triggers a sequence of window messages.

The user can close an application window by clicking the Close button, or by using a keyboard shortcut such as ALT+F4. Any of these actions causes the window to receive a `WM_CLOSE` message. The `WM_CLOSE` message gives you an opportunity to prompt the user before closing the window. If you really do want to close the window, call the `DestroyWindow` function. Otherwise, simply return zero from the `WM_CLOSE` message, and the operating system will ignore the message and not destroy the window.

Here is an example of how a program might handle `WM_CLOSE`.

```c++
case WM_CLOSE:
    if (MessageBox(hwnd, L"Really quit?", L"My application", MB_OKCANCEL) == IDOK)
    {
        DestroyWindow(hwnd);
    }
    // Else: User canceled. Do nothing.
    return 0;
```

In this example, the `MessageBox` function shows a modal dialog that contains OK and Cancel buttons. If the user clicks OK, the program calls `DestroyWindow`. Otherwise, if the user clicks Cancel, the call to `DestroyWindow` is skipped, and the window remains open. In either case, return zero to indicate that you handled the message.

If you want to close the window without prompting the user, you could simply call `DestroyWindow` without the call to `MessageBox`. However, there is a shortcut in this case. Recall that `DefWindowProc` executes the default action for any window message. In the case of `WM_CLOSE`, `DefWindowProc` automatically calls `DestroyWindow`. That means if you ignore the `WM_CLOSE` message in your switch statement, the window is destroyed by default.

When a window is about to be destroyed, it receives a `WM_DESTROY` message. This message is sent after the window is removed from the screen, but before the destruction occurs (in particular, before any child windows are destroyed).

In your main application window, you will typically respond to `WM_DESTROY` by calling `PostQuitMessage`.

```c++
case WM_DESTROY:
    PostQuitMessage(0);
    return 0;
```

We saw in the *Window Messages* section that `PostQuitMessage` puts a `WM_QUIT` message on the message queue, causing the message loop to end.

Here is a flow chart showing the typical way to process `WM_CLOSE` and 
`WM_DESTROY` messages:

![Close the Window](codehome/src/img/backward/wmclose-01.png)

<EndMarkdown>