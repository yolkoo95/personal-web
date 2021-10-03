# C Pointer

## Table of Contents
- [Star Type](#startype)
	- [Width](#width)
	- [Arithmetic](#arithmetic)
		- [Plus and Minus](#plusandminus)
		- [Minus](#minus)
	- [Memory Address](#memoryaddress)
	- [Dereference](#dereference)
	- [Pointer or Array](#pointerorarray)
	- [CE Simulation](#cesimulation)
- [Array and String](#arrayandstring)
	- [Array as Arguments](#arrayasarguments)
	- [C String](#cstring)
	- [String and Pointer](#stringandpointer)
	- [String Function](#stringfunction)
	- [Pointer Array](#pointerarray)
- [Array Pointer](#arraypointer)
- [Function Pointer](#functionpointer)

<TableEndMark>

<!-- Insert content here -->

## Star Type

Star type, which is also called pointer, is a very special type in C, which is used to save memory address of a variable, struct or function.

```c
// declaration of a star type variable
TYPE* p_name
```

### Width

As always, there are three main points to master a type -- width, storage, and function scope.

```c
#include "stdio.h"

typedef struct foo {
    int a;
    char ch;
} Foo;

void func() {

}

int main(int argc, char* argv[]) {
    // builtin type
    int* p_int;     // 4 bytes
    short* p_short;     // 4 bytes
    char* p_char;   // 4 bytes

    // struct
    Foo* p_foo;     // also 4 bytes

    // function
    void (*p_func)() = &func;
    printf("%d\n", sizeof(p_func));
}
```

```c
4
```

### Arithmetic

Now we will explore some arithmetic operation on pointer.

#### Plus and Minus

```c
int main(int argc, char* argv[]) {
    // builtin type
    int* p_int;     // 4 bytes
    short* p_short;     // 4 bytes
    char* p_char;   // 4 bytes

    // struct
    Foo* p_foo;     // also 4 bytes

    // function
    void (*p_func)() = &func;

    p_int++;     // add 4
    p_short++;      // add 2
    p_char++;    // add 1

    p_foo++;     // add 8

    // how about ++ on a function pointer? Illegal!
    // p_func++;
}
```

```c
// add a length of an instance of the struct
28:       p_foo++;
    0040108A 8B 45 F0             mov         eax,dword ptr [ebp-10h]
    0040108D 83 C0 08             add         eax,8
    00401090 89 45 F0             mov         dword ptr [ebp-10h],eax
```

- `--` operation: is same with `++`;

So the equation could be concluded as `addr[end] = addr[begin] + n * sizeof(obj)`.

#### Minus

How about minus a pinter from another pointer?

```c
int main(int argc, char* argv[]) {
    int* p_int1;
    int* p_int2;
    short* p_short1;
    short* p_short2;
    char* p_char1;
    char* p_char2;

    p_int1 = (int*)100;
    p_int2 = (int*)200;
    p_short1 = (short*)100;
    p_short2 = (short*)200;
    p_char1 = (char*)100;
    p_char2 = (char*)200;

    printf("%d\n", p_int2 - p_int1);
    printf("%d\n", p_short2 - p_short1);
    printf("%d\n", p_char2 - p_char1);
}
```

```c
25
50
100
```

Notice that the result equals to `(addr[end] - addr[begin]) / sizeof(obj)`.

*BTW, we are able to compare two pointers.*

### Memory Address

How to get memory address of a variable? use `&` sign.

```c
int a = 1;

int main(int argc, char* argv[]) {
    int b = 2;

    int* pa = &a;
    int* pb = &b;

    return 0;
}
```

```c
15:       int b = 2;
00401068 C7 45 FC 02 00 00 00 mov         dword ptr [ebp-4],2
// searching address directly for global variables
16:       int* pa = &a;
0040106F C7 45 F8 30 4A 42 00 mov         dword ptr [ebp-8],offset _a (00424a30)
// searching address indirectly, with the help of register
17:       int* pb = &b;
00401076 8D 45 FC             lea         eax,[ebp-4]
00401079 89 45 F4             mov         dword ptr [ebp-0Ch],eax
```

### Dereference

`*` used in places other than declaration is for dereference, meaning access the value of some memory to which pointer points.

```c
int a = 1;

int main(int argc, char* argv[]) {
    int b = 2;

    int* pa = &a;
    int* pb = &b;

    printf("%d\n", *pa);
    printf("%d\n", *pb);

    return 0;
}
```

```c
21:       printf("%d\n", *pa);
0040D47C 8B 4D F8             mov         ecx,dword ptr [ebp-8]
0040D47F 8B 11                mov         edx,dword ptr [ecx]
0040D481 52                   push        edx
0040D482 68 1C 20 42 00       push        offset string "%d\n" (0042201c)
0040D487 E8 54 02 00 00       call        printf (0040d6e0)
0040D48C 83 C4 08             add         esp,8
22:       printf("%d\n", *pb);
0040D48F 8B 45 F4             mov         eax,dword ptr [ebp-0Ch]
0040D492 8B 08                mov         ecx,dword ptr [eax]
0040D494 51                   push        ecx
0040D495 68 1C 20 42 00       push        offset string "%d\n" (0042201c)
0040D49A E8 41 02 00 00       call        printf (0040d6e0)
0040D49F 83 C4 08             add         esp,8
```

When comes to dereference, one thing that has to discuss is the relationship between `*(p+n)` and `p[n]`.

```c
int main(int argc, char* argv[]) {
    // uninitialized pointer is super DANGEROUS, but now we ignore it
    char* p;

    printf("%d %d\n", *(p+1), p[1]);
}
```

```c
// don't forget the default is __cdecall
34:       printf("%d %d\n", *(p+1), p[1]);
// p[1]
00401228 8B 45 FC             mov         eax,dword ptr [ebp-4]
0040122B 0F BE 48 01          movsx       ecx,byte ptr [eax+1]
0040122F 51                   push        ecx
// *(p+1)
00401230 8B 55 FC             mov         edx,dword ptr [ebp-4]
00401233 0F BE 42 01          movsx       eax,byte ptr [edx+1]
00401237 50                   push        eax
00401238 68 A4 2F 42 00       push        offset string "%d %d\n" (00422fa4)
0040123D E8 8E 00 00 00       call        printf (004012d0)
00401242 83 C4 0C             add         esp,0Ch
```

From the perspective of assembler, `*(p+n)` and `p[n]` are same. Now let's move further into the relationship between pointer and multi-dimensional array.

```c
int main(int argc, char* argv[]) {
    // uninitialized pointer is super DANGEROUS, but now we ignore it
    char** p;

    printf("%d %d\n", *(*(p+1)+1), p[1][1]);
}
```

```c
34:       printf("%d %d\n", *(*(p+1)+1), p[1][1]);
// p[1][1]
00401228 8B 45 FC             mov         eax,dword ptr [ebp-4]
// the size of char* is 4
0040122B 8B 48 04             mov         ecx,dword ptr [eax+4]
// the size of char is 1
0040122E 0F BE 51 01          movsx       edx,byte ptr [ecx+1]
00401232 52                   push        edx
// *(*(p+1)+1)
00401233 8B 45 FC             mov         eax,dword ptr [ebp-4]
00401236 8B 48 04             mov         ecx,dword ptr [eax+4]
00401239 0F BE 51 01          movsx       edx,byte ptr [ecx+1]
0040123D 52                   push        edx
0040123E 68 A4 2F 42 00       push        offset string "%d %d\n" (00422fa4)
00401243 E8 88 00 00 00       call        printf (004012d0)
00401248 83 C4 0C             add         esp,0Ch
```

Notice that `*(*(p+n)+n)` and `p[n][n]` are same.

BTW, `->` is a keyword in C reserved for dereference of a struct pointer.

```c
typedef struct foo {
    int a;
    char ch;
    short b;
} Foo;

Foo* p = (Foo*)001024;

printf("%d %c %d\n", p->a, p->ch, p->b);
```

### Pointer or Array

Is there any relation between pointer and array? Of course, the address of the first element of an array is the base address of that array, thereby also called `base address`. (`eg. addr(a[0]) == addr(arr(a))`). Then the question is if we are able to manipulate array by pointer, given that array is just a sequence of memory blocks.

```c
int main(int argc, char* argv[]) {
	char arr[10];
    int i;
    char* p = arr;			

    // initialize array		
    for(i = 0; i < 10; i++) {			
        *(p+i) = i * 2;		
    }			

    // print array         
    for(i = 0; i < 10; i++) {			
        printf("%d\n", *(p+i));		
    }	

    return 0;
}	
```

### CE Simulation

Cheat Engine (CE) is a tool that helps you figure out how a game/application works and make modifications to it. One of basic function is to search memory address. Now we will use pointer to simulate this function.

```c
#include "stdio.h"

char data[100] = {
	0x00,0x64,0x00,0x00,0x00,0x05,0x06,0x07,0x07,0x09,
	0x00,0x20,0x10,0x03,0x03,0x0C,0x00,0x00,0x44,0x00,	
	0x00,0x33,0x00,0x47,0x0C,0x0E,0x00,0x0D,0x00,0x11,	
	0x00,0x00,0x00,0x02,0x64,0x00,0x00,0x00,0xAA,0x00,
	0x00,0x00,0x64,0x00,0x00,0x00,0x00,0x02,0x00,0x00,
	0x00,0x00,0x02,0x00,0x74,0x0F,0x41,0x00,0x00,0x00,
	0x01,0x00,0x00,0x00,0x05,0x00,0x00,0x00,0x0A,0x00,
	0x00,0x02,0x74,0x0F,0x41,0x00,0x06,0x08,0x00,0x00,
	0x00,0x00,0x00,0x64,0x00,0x0F,0x00,0x00,0x0D,0x00,
	0x00,0x00,0x23,0x00,0x00,0x64,0x00,0x00,0x64,0x00
};

void searchByChar(char target) {
	int i = 0;
	char* ptr = &data;
	for (; i < sizeof(data)/sizeof(char); i++) {
		if (*(ptr+i) == target) {
			printf("%x\n", ptr+i);
		}
	}
}

// wrongdoing with int !!! 'cause we don't know which the start address is
void searchByInt_Wrong(int target) {
	int i = 0;
	int* ptr = &data;
	for (; i < sizeof(data)/sizeof(int); i++) {
		if (*(ptr+i) == target) {
			printf("%x\n", ptr+i);
		}
	}
}

void searchByInt(int target) {
	int i = 0;
	int* baseAddr = &data;
	int* ptr;
	for (; i <= sizeof(data) - sizeof(int); i++) {
        // add 1, instead of add sizeof(int)
		int addr = (int)baseAddr;
		ptr = (int*)(addr + i);
		if (*ptr == target) {
			printf("%x\n", ptr);
		}
	}
}

void CESimulation() {
	// searchByChar(100);
	searchByInt(100);
}

int main(int argc, char* argv[]) {
	
	CESimulation();

    return 0;
}	
```

## Array and String

In previous notes, we have discussed multi-dimensional array. Now we will proceed to talk about array and some of its features.

### Array as Arguments

The first topic we will discuss is array as arguments of a function.

```c
#include "stdio.h"

void printArray(int arr[],int nLength) {	
	int i = 0;
    for (; i < nLength; i++) {
        printf("%d\n", arr[i]);
	}
}	

int main(int argc, char* argv[]) {
	int arr[10] = {
		0, 1, 2, 3, 4,
		5, 6, 7, 8, 9
	};

	printArray(arr, 10);

    return 0;
}
```

```c
// caller:
16:       printArray(arr, 10);
0040128E 6A 0A                push        0Ah
// notice that the base address of array is passed
00401290 8D 45 D8             lea         eax,[ebp-28h]
00401293 50                   push        eax
00401294 E8 6C FD FF FF       call        @ILT+0(_printArray) (00401005)
00401299 83 C4 08             add         esp,8

// callee:
004011B0 55                   push        ebp
004011B1 8B EC                mov         ebp,esp
// notice that callee function only allocate 1 more byte for temporary variable
004011B3 83 EC 44             sub         esp,44h
004011B6 53                   push        ebx
004011B7 56                   push        esi
004011B8 57                   push        edi
004011B9 8D 7D BC             lea         edi,[ebp-44h]
004011BC B9 11 00 00 00       mov         ecx,11h
004011C1 B8 CC CC CC CC       mov         eax,0CCCCCCCCh
004011C6 F3 AB                rep stos    dword ptr [edi]
4:        int i = 0;
004011C8 C7 45 FC 00 00 00 00 mov         dword ptr [ebp-4],0
5:        for (; i < nLength; i++) {
004011CF EB 09                jmp         printArray+2Ah (004011da)
004011D1 8B 45 FC             mov         eax,dword ptr [ebp-4]
004011D4 83 C0 01             add         eax,1
004011D7 89 45 FC             mov         dword ptr [ebp-4],eax
004011DA 8B 4D FC             mov         ecx,dword ptr [ebp-4]
004011DD 3B 4D 0C             cmp         ecx,dword ptr [ebp+0Ch]
004011E0 7D 19                jge         printArray+4Bh (004011fb)
6:            printf("%d\n", arr[i]);
004011E2 8B 55 FC             mov         edx,dword ptr [ebp-4]
004011E5 8B 45 08             mov         eax,dword ptr [ebp+8]
004011E8 8B 0C 90             mov         ecx,dword ptr [eax+edx*4]
004011EB 51                   push        ecx
004011EC 68 20 20 42 00       push        offset string "%d\n" (00422020)
004011F1 E8 DA 00 00 00       call        printf (004012d0)
004011F6 83 C4 08             add         esp,8
7:        }
004011F9 EB D6                jmp         printArray+21h (004011d1)
8:    }
```

From assembly language, we know that only base address and size of an array is passed to callee function, instead of copying all elements in that array. That's how array works as arguments in C language.

### C String

C string is very important in that it has some differences from other languages for history problem. C string can be seen as a char array, but is ended with `\0`, termed end symbol.

```c
#include "stdio.h"
#include "string.h"

int main(int argc, char* argv[]) {
	char arr[6] = {
		'C', 'h', 'i', 'n', 'a', '\0'
	};
	char s[] = "China";

	printf("%d\n", sizeof(arr));  // 6
    printf("%d\n", strlen(arr));  // 5, do not count '\0'
	printf("%s\n", arr);          // China
	printf("%d\n", sizeof(s));    // 6
	printf("%d\n", strlen(s));    // 5
	printf("%s\n", s);            // China

    return 0;
}
```

From the experiment above, we know that string can be replaced by char array, and vice versa.

### String and Pointer

Then next topic is how a string is initialized. Guess what will happen when executing following code?

```c
char* p = "China";
char s[] = "China";

int main(int argc, char* argv[]) {
    
    *(p+1) = 'H';
    s[1] = 'H';
}
```

```c
ERROR: access denied!
```

Why? Because we access read-only memory. Remember that memory is divided roughly into 5 spaces -- `code space`, `stack space`, `heap space`, `global variable`, and `constant space`, where `constant space` is read only. But how? Let's dig into it.

```c
16:       *(p+1) = 'H';
0040D978 A1 94 4A 42 00       mov         eax,[_p (00424a94)]
// 0x00424a94 is in read-only constant space
0040D97D C6 40 01 48          mov         byte ptr [eax+1],48h
// s[] is in global variable space, which is readable and writable
17:       s[1] = 'H';
0040D981 C6 05 99 4A 42 00 48 mov         byte ptr [_s+1 (00424a99)],48h
```

To make it clear, let's see following code,

```c
int main(int argc, char* argv[]) {
	char* p = "China";
    char s[] = "China";
    
    *(p+1) = 'H';
    s[1] = 'H';
}
```

```c
13:       char* p = "China";
0040D978 C7 45 FC A4 2F 42 00 mov         dword ptr [ebp-4],offset string "China" (00422fa4)
14:       char s[] = "China";
0040D97F A1 A4 2F 42 00       mov         eax,[string "China" (00422fa4)]
0040D984 89 45 F4             mov         dword ptr [ebp-0Ch],eax
0040D987 66 8B 0D A8 2F 42 00 mov         cx,word ptr [string "China"+4 (00422fa8)]
0040D98E 66 89 4D F8          mov         word ptr [ebp-8],cx
15:
16:       *(p+1) = 'H';
0040D992 8B 55 FC             mov         edx,dword ptr [ebp-4]
0040D995 C6 42 01 48          mov         byte ptr [edx+1],48h
17:       s[1] = 'H';
0040D999 C6 45 F5 48          mov         byte ptr [ebp-0Bh],48h
```

We will find:

- `char* p = "China"`: p is only a pointer to a string constant, "China".
- `char s[] = "China"`: since string constant "China" takes 5 bytes, the assembler copy it into `s[]` by 2 steps. Copy 4 bytes by `eax` first, and then the last one with register `cx`. the name of array, `s`, saves its base address.

### String Function

- `strlen`

```c
int strlen(char* s) {
    int ret = 0;
    while ((*s++) != '\0') {
        count++;
    }

    return ret;
}
```

- `strcpy`

```c
char* strcpy(char* dest, char* src) {
    char* ret = dest;

    // noting that there are three steps,
    // 1. assignment
    // 2. self-increment
    // 3. if *dest == \0
    while ((*dest++) = (*src++));

    return ret;
}
```

- `strcat`

```c
char* strcat(char* dest, char* src) {
    char* ret = dest;
    
    // move dest to '\0'
    while (*dest != '\0') {
        dest++;
    }

    while ((*dest++) = (*src++));

    return ret;
}
```

- `strcmp`

```c
// same return 1, else return 0
int strcmp(char* src1, char* src2) {
    int ret = 1;

    if (strlen(src1) != strlen(src2)) {
        return 0;
    }

    for (; *src1 != '\0'; src1++) {
        if (*src1 != *src2) {
            ret = 0;
        }

        src2++;
    }

    return ret;
}
```

### Pointer Array

Pointer array is self-explanatory. each element of the array is a pointer, which is often used in saving keywords of a language.

```c
// each element is a char* pointer to a constant
char* keywords[] = {
    "if",
    "else",
    "for",
    "switch"
};
```

## Array Pointer

Array pointer is a pointer to an array.

```c
TYPE (*p)[n];
```

```c
int main(int argc, char* argv[]) {
    // declaration
    int (*p)[5];

    // assignment
    p = (int (*)[5])001024;

    // size
    printf("%d\n", sizeof(p));   // 4

    // arithmetic
    p++ // add sizeof(int arr[5])    
}
```

Now we will explore a code that seems strange,

```c
int main(int argc, char* argv[]) {
    int arr[10] = {
        0, 1, 2, 3, 4,
        5, 6, 7, 8, 9
    };

    int (*p)[2] = (int (*)[2])arr;

    printf("%d\n", p[1][1]);    // 3

    return 0;
}
```

TIP: `int (*p)[2] = (int (*)[2])arr;`, `p` points to arr, that is the value of p is base address of `arr`, `&arr[0]`, rather than `arr[0]`;

```c
31:       int arr[10] = {
32:           0, 1, 2, 3, 4,
00401228 C7 45 D8 00 00 00 00 mov         dword ptr [ebp-28h],0
0040122F C7 45 DC 01 00 00 00 mov         dword ptr [ebp-24h],1
00401236 C7 45 E0 02 00 00 00 mov         dword ptr [ebp-20h],2
0040123D C7 45 E4 03 00 00 00 mov         dword ptr [ebp-1Ch],3
00401244 C7 45 E8 04 00 00 00 mov         dword ptr [ebp-18h],4
33:           5, 6, 7, 8, 9
0040124B C7 45 EC 05 00 00 00 mov         dword ptr [ebp-14h],5
00401252 C7 45 F0 06 00 00 00 mov         dword ptr [ebp-10h],6
00401259 C7 45 F4 07 00 00 00 mov         dword ptr [ebp-0Ch],7
00401260 C7 45 F8 08 00 00 00 mov         dword ptr [ebp-8],8
34:       };
00401267 C7 45 FC 09 00 00 00 mov         dword ptr [ebp-4],9
35:
36:       int (*p)[2] = (int (*)[2])arr;
0040126E 8D 45 D8             lea         eax,[ebp-28h]
00401271 89 45 D4             mov         dword ptr [ebp-2Ch],eax
37:
38:       printf("%d\n", p[1][1]);    // 3
00401274 8B 4D D4             mov         ecx,dword ptr [ebp-2Ch]
// why +0x0C? IMPORTANT
00401277 8B 51 0C             mov         edx,dword ptr [ecx+0Ch]
0040127A 52                   push        edx
0040127B 68 AC 2F 42 00       push        offset string "%d\n" (00422fac)
00401280 E8 4B 00 00 00       call        printf (004012d0)
00401285 83 C4 08             add         esp,8
```

`p[1][1] == *(*(p+1)+1)`, which seems like arr[10] is divided as 5 `arr[2]`s, thereby `arr[10]` is reshaped as a 2-d array `arr[5][2]`. From the perspective of assembler, we just get the value of `arr[1][1]`.

To step further, try following code, what's the output?

```c
#include "stdio.h"

char data[100] = {
	0x00,0x64,0x00,0x00,0x00,0x05,0x06,0x07,0x07,0x09,	
	0x00,0x20,0x10,0x03,0x03,0x0C,0x00,0x00,0x44,0x00,	
	0x00,0x33,0x00,0x47,0x0C,0x0E,0x00,0x0D,0x00,0x11,	
	0x00,0x00,0x00,0x02,0x64,0x00,0x00,0x00,0xAA,0x00,
	0x00,0x00,0x64,0x00,0x00,0x00,0x00,0x02,0x0A,0x0B,
	0x0C,0x0D,0x02,0x00,0x74,0x0F,0x41,0x00,0x00,0x00,
	0x01,0x00,0x00,0x00,0x05,0x00,0x00,0x00,0x0A,0x00,
	0x00,0x02,0x74,0x0F,0x41,0x00,0x06,0x08,0x00,0x00,
	0x00,0x00,0x00,0x64,0x00,0x0F,0x00,0x00,0x0D,0x00,
	0x00,0x00,0x23,0x00,0x00,0x64,0x00,0x00,0x64,0x00
};

int main(int argc, char* argv[]) {
    // access char array with an int array pointer
    int (*p)[5] = (int (*)[5])data;
    // offset = 2 * 5 * sizeof(int) + 2 * sizeof(int)
    printf("%x\n", *(*(p+2) + 2));  // 0D0C0B0A 

    char (*p_ch)[2][3] = (char (*)[2][3])data;
    // offset = 1 * 2 * 3 * sizeof(char) + 2 * 3 * sizeof(char) + 3 * sizeof(char)
    printf("%x\n", *(*(*(p_ch+1) + 2) + 3));  // 0C
}
```

The idea here is that pointer has noting to do with what it points to, say int pointer must point to an int element. *The type of pointer only tell the assembler how to access data*.

## Function Pointer

Function pointer, as its name shows, points to a function.

```c
RET_TYPE (*p_func)(Arguments);
```

```c
int func(int x, int y) {
    return 0;
}

int main(int argc, char* argv[]) {
    // declaration
    int (*p_func)(int, int);
    // assignment
    p_func = (int (*)(int, int))func;
    // or
    p_func = func;

    // we CANNOT place arithmetic operation on function pointer
}
```

By now, one practical function of function pointer is to add shell as we saw before.

```c
#include "stdio.h"

int addTwo(int x, int y) {
    return x + y;
}

typedef int *(pfunc)(int x, int y);

int main(int argc, char* argv[]) {
    pfunc pf = (pfunc)addTwo; # the nature of function name is address
    printf("%x", pf(3, 4));
    
    return 0;
}
```

we could translate code above as following code,

```c
#include "stdio.h"

unsigned char func[] = 
{
    0x55, 0x8B, 0xEC, 0x83, 0xEC, 0x54, 0xC0, 0xE5, 0xCC, 0xBE,
    0x67, 0x01, 0xDF, 0x7F, 0xB8, 0xE2, 0xEC, 0x54, 0xC0, 0xE5,
    0x2C, 0xE3, 0xEE, 0x7B, 0x2R, 0xE3, 0xC4, 0x77, 0x04, 0x2B
}

typedef int *(pfunc)(int x, int y);

int main(int argc, char* argv[]) {
    pfunc pf = (int (*)(int, int))&func;
    printf("%x", pf(3, 4));
    
    return 0;
}
```

<EndMarkdown>