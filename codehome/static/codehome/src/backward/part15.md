# PE Seg.6

## Table of Contents
- [Library](#library)
	- [Differences](#differences)
	- [Static Library](#staticlibrary)
	- [Dynamic Link Library](#dynamiclinklibrary)

<TableEndMark>

## Library

A library is a collection of pre-compiled pieces of code called functions. The library contains common functions, and they form a package called — a **library**. Functions are blocks of code that get reused throughout the program. Using the pieces of code again in a program saves time. It keeps the programmer from rewriting the code several times. For programmers, libraries provide reusable functions, data structures, classes and so forth.

A library is not executable and that is a key difference from processes and applications. Libraries play their role at run time or compile time. In the C programming language, we have two types of libraries: **dynamic libraries** and **static libraries**.

### Differences

When using a **dynamic library**, the programmer is referencing that library when it needs to at runtime. For instance, to access the string length function from the `stdio.h` - you can access it dynamically.

It will find the program’s library reference at runtime because of the dynamic loader. It then loads that string length function into memory. Thus, the dynamic library accessibility must be readily available or it becomes powerless. It keeps the library independent to the executable when comes to compiling.

Advantages and Disadvantages of Dynamic Libraries:

- It only needs one copy at runtime. It is dependent on the application and the library being closely available to each other.
- Multiple running applications use the same library without the need of each file having its own copy.
- They hold smaller files and keep module independently.
- Dynamic libraries are linked at run-time. It does not require recompilation and relinking when the programmer makes a change.
- However, what if the dynamic library becomes corrupt? The executable file may not work because it lives outside of the executable and is vulnerable to breaking.

![Static vs. Dynamic Linking](codehome/src/img/backward/DynamicAndStatic.png)

However at compile time, applications utilize **static libraries**. All the copies of the functions get placed into the application file because they are needed to run the process.

Advantages and Disadvantages of Static Libraries:

- Static libraries resist vulnerability because it lives inside the executable file.
- The speed at run-time occurs faster because its object code (binary) is in the executable file. Thus, calls made to the functions get executed quicker. Remember, the dynamic library lives outside of the executable, so calls would be made from the outside of the executable.
- Changes made to the files and program require relinking and recompilation
- File size is much larger.

### Static Library

Then we will demonstrate how to use static library with VC++6.0.

```c
// TODO STEP1: create a new static project TestStatic and generate a new class Static.

// Static.h: interface for the Static class.

#if !defined(AFX_STATIC_H__EECA4D62_97C8_4B64_85E3_2056DBD903AF__INCLUDED_)
#define AFX_STATIC_H__EECA4D62_97C8_4B64_85E3_2056DBD903AF__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

class Static  
{
public:
	Static();
	virtual ~Static();

};

#endif // !defined(AFX_STATIC_H__EECA4D62_97C8_4B64_85E3_2056DBD903AF__INCLUDED_)


// Static.cpp: implementation of the Static class.
#include "Static.h"

//////////////////////////////
// Construction/Destruction //
//////////////////////////////

Static::Static()
{

}

Static::~Static()
{

}
```

```c
// TODO STEP2: insert lib functions

// Static.h: interface for the Static class.

#if !defined(AFX_STATIC_H__EECA4D62_97C8_4B64_85E3_2056DBD903AF__INCLUDED_)
#define AFX_STATIC_H__EECA4D62_97C8_4B64_85E3_2056DBD903AF__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

int Plus(int x, int y);
int Sub(int x, int y);
int Mul(int x, int y);
int Div(int x, int y);

class Static  
{
public:
	Static();
	virtual ~Static();

};

#endif // !defined(AFX_STATIC_H__EECA4D62_97C8_4B64_85E3_2056DBD903AF__INCLUDED_)


// Static.cpp: implementation of the Static class.
#include "Static.h"

int Plus(int x, int y) {
	return x + y;
}

int Sub(int x, int y) {
	return x - y;
}

int Mul(int x, int y) {
	return x * y;
}

int Div(int x, int y) {
	return x / y;
}

//////////////////////////////
// Construction/Destruction //
//////////////////////////////

Static::Static()
{

}

Static::~Static()
{

}
```

After compiling, we will get a file `TestStatic.lib`.

![A New Generated Lib File](codehome/src/img/backward/TestStaticLib.png)

Then if we want use static library `TestStatic.lib`, we just need two files - `TestStatic.lib` and `Static.h`. Copy these two files into working directory.

Assuming that we will use the static library in a new project `Test`, noting that we have to use suffix `.cpp` since there includes c++ class.

```c
// TODO STEP3: main.cpp
#include <stdio.h>
#include "Static.h"

// method 1:
// use pragma syntax
// #pragma comment (lib, "LIB_NAME")
#pragma comment (lib, "TestStatic.lib")

// method 2:
// configure project: project setting -> link -> add TestStatic.lib

int main(int argc, char* argv[]) {
	printf("%d\n", Plus(1, 2));

	return 0;
}
```

Looking at its assembly language, it will be found that the function `Plus` is put into code section, which means that it is compiled together with main function. That's a core feature of static library.

```c
12:       printf("%d\n", Plus(1, 2));
00401028 6A 02                push        2
0040102A 6A 01                push        1
0040102C E8 3F 00 00 00       call        Plus (00401070)
00401031 83 C4 08             add         esp,8
00401034 50                   push        eax
00401035 68 1C 20 42 00       push        offset string "%d\n" (0042201c)
0040103A E8 B1 01 00 00       call        printf (004011f0)
0040103F 83 C4 08             add         esp,8
```

### Dynamic Link Library

Now let's try dynamic link library.

```c
// TODO STEP1: create and compile to generate a dll file
// myDll.h: interface for the myDll class.

#if !defined(AFX_MYDLL_H__89113A2B_9A2C_4E98_AF2E_750F09253B1E__INCLUDED_)
#define AFX_MYDLL_H__89113A2B_9A2C_4E98_AF2E_750F09253B1E__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

// where, 'extern' is global symbol
// "C" tells system to compile in C convention
// 'dllexport' tells system to this is an export function declaration
// noting that calling convention is put ahead of return type here which is special. 
extern "C" _declspec(dllexport) __stdcall int Plus(int x, int y);
extern "C" _declspec(dllexport) __stdcall int Sub(int x, int y);
extern "C" _declspec(dllexport) __stdcall int Mul(int x, int y);
extern "C" _declspec(dllexport) __stdcall int Div(int x, int y);


#endif // !defined(AFX_MYDLL_H__89113A2B_9A2C_4E98_AF2E_750F09253B1E__INCLUDED_)


// myDll.cpp: implementation of the myDll class.

#include "myDll.h"

//////////////////////////////
// Construction/Destruction //
//////////////////////////////

int __stdcall Plus(int x, int y) {
	return x + y;
}

int __stdcall Sub(int x, int y) {
	return x - y;
}

int __stdcall Mul(int x, int y) {
	return x * y;
}

int __stdcall Div(int x, int y) {
	return x / y;
}
```

Using `depends` tool in VC++6.0, it will list description of `myDLL.dll`.

![Description of myDLL](codehome/src/img/backward/myDLL.png)

Now the next question is how to use dll. There are two ways - link explicitly and implicitly.

##### Implicit Link

- Preparation: put `*.lib` and `*.dll` into working directory. Different from `*.lib` in static library, it includes references to compiled function in `*.dll` rather than function code that is not compiled as static library does.
- Comment: add `#pragma comment (lib, "LIB_NAME")`.
- Reference: `extern "C" _declspec(dllimport) __stdcall int foo(TYPE NAME)`;

```c
// main.cpp
#include <stdio.h>

#pragma comment (lib, "myDLL.lib")

extern "C" _declspec(dllimport) __stdcall int Plus(int x, int y);
extern "C" _declspec(dllimport) __stdcall int Sub(int x, int y);
extern "C" _declspec(dllimport) __stdcall int Mul(int x, int y);
extern "C" _declspec(dllimport) __stdcall int Div(int x, int y);

int main(int argc, char* argv[]) {
	printf("%d\n", Plus(1, 2));

	return 0;
}
```

```c
// Output:
3
```

Well done, now let's dig into `myDLL`.

![Address of DLL](codehome/src/img/backward/myDLL2.png)

We will find that DLL file is in its own space, `10001250`, rather than in code section in static library case.

##### Explicit Link

What's different from implicitly link is that we have to refer to function in `*.dll` file manually.

- Define Function Pointer: e.g. `typedef int (__stdcall *pPlus)(int, int)`.
- Declare Pointer: e.g. `pPlus myPlus`.
- Load Dynamically: `HINSTANCE hModule = LoadLibrary("myDll.dll")`, `H` means handles, which is type of `DWORD`.
- Get Function Address: `myPlus = (pPlus)GetProcAddress(hModule, "_Plus@8")`, where `_` responds to `__stdcall`, `@8` responds to argument list (`int, int`). Also we could find function name by tools `depends` as follows,

![Get Function Name](codehome/src/img/backward/myDLL3.png)

```c
// main.cpp:
#include <stdio.h>
#include <windows.h>

typedef int (__stdcall *pPlus)(int, int);

int main(int argc, char* argv[]) {
	pPlus myPlus;
	
	HINSTANCE hModule = LoadLibrary("myDLL.dll");
	myPlus = (pPlus)GetProcAddress(hModule, "_Plus@8");

	printf("%d\n", myPlus(1, 2));

	return 0;
}
```	

##### Anonymize Function

In order to keep our code safe, we will normally anonymize our function since function name will expose the purpose of a function.

- Declare and Definition: without `export` or `import` keywords.
- DEF File: create a mapping file, `*.def`.
- Export by Export Number.

```c
// TODO STEP1: create a new dll
// NONameDLL.h: interface for the NONameDLL class.

#if !defined(AFX_NONAMEDLL_H__C3301509_4885_4AC7_8B26_7F58F218E75E__INCLUDED_)
#define AFX_NONAMEDLL_H__C3301509_4885_4AC7_8B26_7F58F218E75E__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

int __stdcall Plus(int x, int y);
int __stdcall Sub(int x, int y);
int __stdcall Mul(int x, int y);
int __stdcall Div(int x, int y);

#endif // !defined(AFX_NONAMEDLL_H__C3301509_4885_4AC7_8B26_7F58F218E75E__INCLUDED_)
```

```c
// NONameDLL.cpp: implementation of the NONameDLL class.
#include "NONameDLL.h"

int __stdcall Plus(int x, int y) {
	return x + y;
}

int __stdcall Sub(int x, int y) {
	return x - y;
}

int __stdcall Mul(int x, int y) {
	return x * y;
}

int __stdcall Div(int x, int y) {
	return x / y;
}
```

```c
// TODO STEP2: create map file
// map.def:
EXPORTS

Plus	@12
Sub		@15 NONAME
Mul		@13
Div		@16
```

After compiling, we will get a dll file with anonymized function.

![Anonymized Function](codehome/src/img/backward/myDLL4.png)

In the next notes, we will discuss how to link dynamic library with ordinal.

```c
// explicitly refer to dll
#include <stdio.h>
#include <windows.h>

typedef int (__stdcall *pPlus)(int, int);

int main(int argc, char* argv[]) {
	pPlus myPlus;

	HINSTANCE hModule = LoadLibrary("MoveImageBase.dll");
	myPlus = (pPlus)GetProcAddress(hModule, "Plus");

	printf("%d\n", myPlus(1, 2));

	return 0;
}
```

<EndMarkdown>