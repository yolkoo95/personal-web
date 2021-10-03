# C Language Seg.2

## Table of Contents
- [Overview](#overview)
	- [Type Conversion in Assembly](#typeconversioninassembly)
		- [Data Trimmer](#datatrimmer)
	- [True or False](#trueorfalse)
	- [Logic Operator](#logicoperator)
	- [i++ and ++i](#i++and++i)
- [Data Delivery](#datadelivery)
	- [Return Value](#returnvalue)
	- [Arguments](#arguments)
	- [Temporary Variable](#temporaryvariable)
	- [Array](#array)
		- [Indexing](#indexing)

<TableEndMark>

## Overview

### Type Conversion in Assembly

- `movsx` and `movzx`
`movsx` and `movzx` are two instructions to extend width of data. `movsx`(sign extension) is used to extend signed data while `movzx`(zero extension) for unsigned data.

For signed variable, the assembler will fill 1 on most significant bits when sign bit equals 1, and fill 0 when sign bit equals 0.

```c
void typeConversion() {
    char ch = 0xff;
    short n = ch;
    int i = ch;
}

// how does assembler explain the code? and how to extend for negative number?
4:        char ch = 0xff;
00401048 C6 45 FC FF          mov         byte ptr [ebp-4],0FFh
5:        short n = ch;
0040104C 66 0F BE 45 FC       movsx       ax,byte ptr [ebp-4]
00401051 66 89 45 F8          mov         word ptr [ebp-8],ax
// ax = 0xffff
6:        int i = ch;
00401055 0F BE 4D FC          movsx       ecx,byte ptr [ebp-4]
00401059 89 4D F4             mov         dword ptr [ebp-0Ch],ecx
// ecx = 0xffffffff
```

```c
void typeConversion() {
    char ch = 0x7f;
    short n = ch;
    int i = ch;
}

// how does assembler extension for signed positive number?
4:        char ch = 0x7f;
00401048 C6 45 FC 7F          mov         byte ptr [ebp-4],7Fh
5:        short n = ch;
0040104C 66 0F BE 45 FC       movsx       ax,byte ptr [ebp-4]
00401051 66 89 45 F8          mov         word ptr [ebp-8],ax
// ax = 0x007f
6:        int i = ch;
00401055 0F BE 4D FC          movsx       ecx,byte ptr [ebp-4]
00401059 89 4D F4             mov         dword ptr [ebp-0Ch],ecx
// ecx = 0x0000007f
```

```c
void typeConversion() {
    unsigned char ch = 0x7f;
    unsigned short n = ch;
    unsigned int i = ch;
}

4:        unsigned char ch = 0xff;
00401048 C6 45 FC FF          mov         byte ptr [ebp-4],0FFh
5:        unsigned short n = ch;
0040104C 66 0F B6 45 FC       movzx       ax,byte ptr [ebp-4]
00401051 66 89 45 F8          mov         word ptr [ebp-8],ax
6:        unsigned int i = ch;
// noting that the assembler replace `movzx` with `mov` and `and`
00401055 8B 4D FC             mov         ecx,dword ptr [ebp-4]
// ecx = 0xCCCCCCFF 
00401058 81 E1 FF 00 00 00    and         ecx,0FFh
// ecx = 0x000000FF
0040105E 89 4D F4             mov         dword ptr [ebp-0Ch],ecx
```

#### Data Trimmer

```c
void typeConversion() {
    int i = 0x12345678;
    short n = i;
    char ch = i;
}

// the most significant bits will be discard
4:        int i = 0x12345678;
00401048 C7 45 FC 78 56 34 12 mov         dword ptr [ebp-4],12345678h
5:        short n = i;
0040104F 66 8B 45 FC          mov         ax,word ptr [ebp-4]
00401053 66 89 45 F8          mov         word ptr [ebp-8],ax
// ax = 0x5678
6:        char ch = i;
00401057 8A 4D FC             mov         cl,byte ptr [ebp-4]
0040105A 88 4D F4             mov         byte ptr [ebp-0Ch],cl
// cl = 0x78
```

### True or False

Relational operators(`==`, `!=`, `>=`, `<=`, `>`, and `<`) plays an important role in control flow, but how does it work?

```c
// how does system go with this code?
void relOperator(x, y) {
    int i = x == y;
}

// caller:
004010A8 6A 01                push        1
004010AA 6A 01                push        1
004010AC E8 68 FF FF FF       call        @ILT+20(_typeConversion) (00401019)
004010B1 83 C4 08             add         esp,8

// callee:
4:        int i = x == y;
00401048 8B 45 08             mov         eax,dword ptr [ebp+8]
// clear value
0040104B 33 C9                xor         ecx,ecx
0040104D 3B 45 0C             cmp         eax,dword ptr [ebp+0Ch]
// set cl as 1 if equal
00401050 0F 94 C1             sete        cl
00401053 89 4D FC             mov         dword ptr [ebp-4],ecx
```

- `sete` and `setne`
`sete` and `setne` are complex instructions in assembly language. `sete` means *set if equal*.

### Logic Operator

There are three logic operator in C language -- `&&`, `||`, `!`. Now let's see it from the perspective of assembly language.

```c
void logicOperator(int x, int y, int z) {
    if (x > 1 && y > 1 && z > 1) {
        printf("Yes");
    }
    else {
        printf("No");
    }
}

// caller:
00401108 6A 03                push        3
0040110A 6A 02                push        2
0040110C 6A 01                push        1
0040110E E8 0B FF FF FF       call        @ILT+25(_myCompareUnsigned) (0040101e)
00401113 83 C4 0C             add         esp,0Ch

// callee:
8:        if (x > 1 && y > 1 && z > 1) {
004010A8 83 7D 08 01          cmp         dword ptr [ebp+8],1
004010AC 7E 1B                jle         logicOperator+39h (004010c9)
004010AE 83 7D 0C 01          cmp         dword ptr [ebp+0Ch],1
004010B2 7E 15                jle         logicOperator+39h (004010c9)
004010B4 83 7D 10 01          cmp         dword ptr [ebp+10h],1
004010B8 7E 0F                jle         logicOperator+39h (004010c9)
9:            printf("Yes");
// calling function printf()
004010BA 68 20 20 42 00       push        offset string "Yes" (00422020)
004010BF E8 8C 00 00 00       call        printf (00401150)
004010C4 83 C4 04             add         esp,4
10:       }
11:       else {
004010C7 EB 0D                jmp         logicOperator+46h (004010d6)
12:           printf("No");
004010C9 68 1C 20 42 00       push        offset string "x > y" (0042201c)
004010CE E8 7D 00 00 00       call        printf (00401150)
004010D3 83 C4 04             add         esp,4
```

```c
// this structure of '&&' is featured by consistent 'cmp' and 'jcc'
cmp var1, var2
jcc addr[else]
cmp var1, var2
jcc addr[else]
cmp var1, var2
jcc addr[else]
...  //-|
...  // |--->  case1
...  //-|
jmp addr[End]
...  //-|     <--- addr[else]
...  // |--->  else or case2 
...  //-|

...  //       <--- addr[End]
```

Now let's try `||`,

```c
void logicOperator(int x, int y, int z) {
    if (x > 1 || y > 1 || z > 1) {
        printf("Yes");
    }
    else {
        printf("No");
    }
}

// callee:
8:        if (x > 1 || y > 1 || z > 1) {
004010A8 83 7D 08 01          cmp         dword ptr [ebp+8],1
004010AC 7F 0C                jg          logicOperator+2Ah (004010ba)
004010AE 83 7D 0C 01          cmp         dword ptr [ebp+0Ch],1
004010B2 7F 06                jg          logicOperator+2Ah (004010ba)
004010B4 83 7D 10 01          cmp         dword ptr [ebp+10h],1
004010B8 7E 0F                jle         logicOperator+39h (004010c9)
9:            printf("Yes");
004010BA 68 20 20 42 00       push        offset string "Yes" (00422020)
004010BF E8 8C 00 00 00       call        printf (00401150)
004010C4 83 C4 04             add         esp,4
10:       }
11:       else {
004010C7 EB 0D                jmp         logicOperator+46h (004010d6)
12:           printf("No");
004010C9 68 1C 20 42 00       push        offset string "x > y" (0042201c)
004010CE E8 7D 00 00 00       call        printf (00401150)
004010D3 83 C4 04             add         esp,4
```

```c
// the logic of '||' is somewhat different from '&&'
cmp var1, imm
jcc addr[case1]
cmp var2, imm
jcc addr[case1]
cmp var3, imm
jcc addr[else]  // <--- if fail to meet the last condition, then jcc
...  //-|
...  // |--->  case1
...  //-|
jmp addr[End]
...  //-|      <--- addr of else
...  // |--->  else or case2
...  //-|

...  //        <--- addr of End
```

### i++ and ++i

`int k = i++` equals `int k = i; i = i + 1;`
`int k = ++i` equals `i = i + 1; int k = i;`

In order to make it clear, let's try to understand it in assembly language.

```c
void singleOperator() {
	int i = 1;
	int k = i++;
	int n = ++i;
}

// callee:
17:       int i = 1;
00401108 C7 45 FC 01 00 00 00 mov         dword ptr [ebp-4],1
18:       int k = i++;
0040110F 8B 45 FC             mov         eax,dword ptr [ebp-4]
00401112 89 45 F8             mov         dword ptr [ebp-8],eax
// after assignment to k, [ebp-4] increases itself.
00401115 8B 4D FC             mov         ecx,dword ptr [ebp-4]
00401118 83 C1 01             add         ecx,1
0040111B 89 4D FC             mov         dword ptr [ebp-4],ecx
19:       int n = ++i;
0040111E 8B 55 FC             mov         edx,dword ptr [ebp-4]
00401121 83 C2 01             add         edx,1
00401124 89 55 FC             mov         dword ptr [ebp-4],edx
// [ebp-4] increases itself before assigning value to n.
00401127 8B 45 FC             mov         eax,dword ptr [ebp-4]
0040112A 89 45 F4             mov         dword ptr [ebp-0Ch],eax
```

## Data Delivery

### Return Value

The first thing worth being discussed is how return value transmit between caller and callee. Let's make an experiment and see it from the perspective of assembler.

```c
#include "stdio.h"

int func() {
	return 0;
}

int main(int argc, char* argv[]) {

	int foo = func();

	return 0;
}
```

```c
// the code of stack preparation and destroy is omitted

// caller:
9:        int foo = func();
00401068 E8 9D FF FF FF       call        @ILT+5(_func) (0040100a)
0040106D 89 45 FC             mov         dword ptr [ebp-4],eax

// callee:
4:        return 0;
00401038 33 C0                xor         eax,eax
```

From assembly code, we know that the return value is transmitted by register `EAX`, but only `EAX`? How about when the size of return value is bigger than that of `EAX`?

```c
#include "stdio.h"

__int64 func() {
	return 0x123456789AB;
}

int main(int argc, char* argv[]) {

	__int64 foo = func();

	return 0;
}
```

Guess what will happen?

```c
// caller:
9:        __int64 foo = func();
00401068 E8 9D FF FF FF       call        @ILT+5(_func) (0040100a)
0040106D 89 45 F8             mov         dword ptr [ebp-8],eax
00401070 89 55 FC             mov         dword ptr [ebp-4],edx

// callee:
4:        return 0x123456789AB;
00401038 B8 AB 89 67 45       mov         eax,456789ABh
0040103D BA 23 01 00 00       mov         edx,123h
```

Notice that the lower 4 bytes is stored by `EAX` and higher ones is in `EDX`. Therefore, when the size of return value is bigger than a register, the assembler will use more then one register to carry return value. How about an array with size bigger than the sum of all available registers? We will discuss it later.

Another question is what if the size of return value is smaller than a register, like `short` or `char`?

```c
// just take char as example
char func() {
	return 0x123456789AB;
}

int main(int argc, char* argv[]) {

	char foo = func();

	return 0;
}
```

```c
// caller:
9:        char foo = func();
00401068 E8 9D FF FF FF       call        @ILT+5(_func) (0040100a)
0040106D 88 45 FC             mov         byte ptr [ebp-4],al

// callee:
4:        return 0x123456789AB;
00401038 B0 AB                mov         al,0ABh
```

What's interesting is that the system will cut lower 1 byte and return it with a 8-bit register `al`. **So when comes to assembly language, `int`, `short` or `char` have no meaning except the width of data.**

### Arguments

Given the knowledge in previous notes, arguments can be transferred with registers or stack according to calling conventions -- `__cdecl`, `__stdcall` or `__fastcall`.

In order to explore the essence of arguments transferring, let's do more experiments.

```c
void func(char x, char y, char z) {

}

int main(int argc, char* argv[]) {
    func(0x12, 0x22, 0x32);

    return 0;
}
```

```c
// caller:
8:        func(0x12, 0x22, 0x32);
00401068 6A 32                push        32h
0040106A 6A 22                push        22h
0040106C 6A 12                push        12h
0040106E E8 97 FF FF FF       call        @ILT+5(_func) (0040100a)
00401073 83 C4 0C             add         esp,0Ch

// callee: noting except stack preparation and destroy
```

It's clear that the arguments are read from right to left and stored in memory, but what's the arrangement of the arguments in the stack. a 8-bit char will take 1 byte memory or more?

```c
// the information of memory stack
 EAX = CCCCCCCC EBX = 7FFDC000
 ECX = 00000000 EDX = 00370E48
 ESI = 00000000 EDI = 0012FF80
 EIP = 00401020 ESP = 0012FF24
 EBP = 0012FF80 EFL = 00000202

           +0 +1 +2 +3
 0012FF28  12 00 00 00
 0012FF2C  22 00 00 00
 0012FF30  32 00 00 00
```

Surprising! a char takes 4 bytes in stack memory. Let's see it from another perspective.

```c
int main(int argc, char* argv[]) {
    char a = 0x12;
    char b = 0x22;
    char c = 0x32;

    func(a, b, c);

    return 0;
}
```

```c
// caller: why it takes 4 byte in memory stack
8:        char a = 0x12;
00401058 C6 45 FC 12          mov         byte ptr [ebp-4],12h
9:        char b = 0x22;
0040105C C6 45 F8 22          mov         byte ptr [ebp-8],22h
10:       char c = 0x32;
00401060 C6 45 F4 32          mov         byte ptr [ebp-0Ch],32h
11:
12:       func(a, b, c);
00401064 8A 45 F4             mov         al,byte ptr [ebp-0Ch]
00401067 50                   push        eax
00401068 8A 4D F8             mov         cl,byte ptr [ebp-8]
0040106B 51                   push        ecx
0040106C 8A 55 FC             mov         dl,byte ptr [ebp-4]
0040106F 52                   push        edx
00401070 E8 95 FF FF FF       call        @ILT+5(_func) (0040100a)
00401075 83 C4 0C             add         esp,0Ch
```

This example also shows how the variable of caller is transferred to callee -- with registers.

Therefore, from standpoint of assembler, the argument defined by char will take the same amount of memory as the one defined by int. **This behavior follows the idea of uniform, which will speed up our machine. Although some spaces are indeed being wasted, `word alignment` helps computer index or search memory address faster.** 

Given that, can we do operation like this, `int n = x;`

```c
void func(char x, char y, char z) {
    int n = x;
}

int main(int argc, char* argv[]) {
    char a = 0x12;
    char b = 0x22;
    char c = 0x32;

    func(a, b, c);

    return 0;
}
```

```c
// callee:
4:        int n = x;
0040D498 0F BE 45 08          movsx       eax,byte ptr [ebp+8]
0040D49C 89 45 FC             mov         dword ptr [ebp-4],eax
```

A char argument indeed takes up 4 byte memory, however when we transfer it into a 4-byte container, it will be extended by `movsx` or `movzx`.

Now we will look at a program with which a new learner are likely to be confused.

```c
#include "stdio.h"

void plus(int x) {
    x = x + 1; // [ebp+8]
}

int main(int argc, char* argv[]) {
    int x = 2;  // [ebp-4]

    plus(x); // transfer argument by push argument
    printf("%d\n", x); // [ebp-4]

    return 0;
}
```

Therefore, the argument is transferred by COPY!

### Temporary Variable

We know that temporary variable is stored in buffer, which is `[ebp-4n] n = 1, 2, 3, ...`. But how big the buffer should be?

```c
// for an empty function
void func() {

}

// callee: the default size of buffer for an empty function is 40h in my machine
0040D480 55                   push        ebp
0040D481 8B EC                mov         ebp,esp
0040D483 83 EC 40             sub         esp,40h
0040D486 53                   push        ebx
0040D487 56                   push        esi
0040D488 57                   push        edi
0040D489 8D 7D C0             lea         edi,[ebp-40h]
0040D48C B9 10 00 00 00       mov         ecx,10h
0040D491 B8 CC CC CC CC       mov         eax,0CCCCCCCCh
0040D496 F3 AB                rep stos    dword ptr [edi]
```

what if add more temporary variables?

```c
void func() {
    int i = 10;
}

// callee: 4 more bytes for an int
0040D480 55                   push        ebp
0040D481 8B EC                mov         ebp,esp
0040D483 83 EC 44             sub         esp,44h
0040D486 53                   push        ebx
0040D487 56                   push        esi
0040D488 57                   push        edi
0040D489 8D 7D BC             lea         edi,[ebp-44h]
0040D48C B9 11 00 00 00       mov         ecx,11h
0040D491 B8 CC CC CC CC       mov         eax,0CCCCCCCCh
0040D496 F3 AB                rep stos    dword ptr [edi]
```

```c
void func() {
    int i = 10;
    char ch = 0xff;
}

// callee: 4 more bytes for a char, although a char takes 1 byte
0040D480 55                   push        ebp
0040D481 8B EC                mov         ebp,esp
0040D483 83 EC 48             sub         esp,48h
0040D486 53                   push        ebx
0040D487 56                   push        esi
0040D488 57                   push        edi
0040D489 8D 7D B8             lea         edi,[ebp-48h]
0040D48C B9 12 00 00 00       mov         ecx,12h
0040D491 B8 CC CC CC CC       mov         eax,0CCCCCCCCh
0040D496 F3 AB                rep stos    dword ptr [edi]
```

Hence no matter what the size of a container is, assembler will allocate 4 bytes for each container. That's also the idea of uniform.

### Array

Array is a collection of some data with the same size.

```c
void func(char x, char y, char z) {
    int arr[10] = {0};
}

// callee:
0040D480 55                   push        ebp
0040D481 8B EC                mov         ebp,esp
0040D483 83 EC 68             sub         esp,68h
0040D486 53                   push        ebx
0040D487 56                   push        esi
0040D488 57                   push        edi
0040D489 8D 7D 98             lea         edi,[ebp-68h]
0040D48C B9 1A 00 00 00       mov         ecx,1Ah
0040D491 B8 CC CC CC CC       mov         eax,0CCCCCCCCh
0040D496 F3 AB                rep stos    dword ptr [edi]
4:        int arr[10] = {0};
// first element is set as 0
0040D498 C7 45 D8 00 00 00 00 mov         dword ptr [ebp-28h],0
// initialize as 0
0040D49F B9 09 00 00 00       mov         ecx,9
0040D4A4 33 C0                xor         eax,eax
0040D4A6 8D 7D DC             lea         edi,[ebp-24h]
0040D4A9 F3 AB                rep stos    dword ptr [edi]
```

How does computer save a char array? Each element takes 1 or 4 bytes?

```c
void func(char x, char y, char z) {
    char arr[10] = {0};
}

// callee:
3:    void func(char x, char y, char z) {
0040D480 55                   push        ebp
0040D481 8B EC                mov         ebp,esp
0040D483 83 EC 4C             sub         esp,4Ch
0040D486 53                   push        ebx
0040D487 56                   push        esi
0040D488 57                   push        edi
0040D489 8D 7D B4             lea         edi,[ebp-4Ch]
0040D48C B9 13 00 00 00       mov         ecx,13h
0040D491 B8 CC CC CC CC       mov         eax,0CCCCCCCCh
0040D496 F3 AB                rep stos    dword ptr [edi]
4:        char arr[10] = {0};
0040D498 C6 45 F4 00          mov         byte ptr [ebp-0Ch],0
0040D49C 33 C0                xor         eax,eax
0040D49E 89 45 F5             mov         dword ptr [ebp-0Bh],eax
0040D4A1 89 45 F9             mov         dword ptr [ebp-7],eax
0040D4A4 88 45 FD             mov         byte ptr [ebp-3],al
```

Notice that the size of buffer increases from `40h` to `4ch`, meaning the assembler allocate `c` or 12 bytes to `char arr[10]`. It will be easier to take in if having a look at memory assignment as follow,

```c
ebp = 0x0012FF14

          +0 +1 +2 +3
0012FF05  CC CC CC 00   // <--- the first element
0012FF09  00 00 00 00   // 4 char as a group assigned with 'eax'
0012FF0D  00 00 00 00   // 4 char as a group assigned with 'eax'
0012FF11  00 CC CC CC   // 1 char left assigned with 'al'
```

Different from temporary variable and arguments, array is recognized as a whole, thereby grouping as 4-byte cluster to assign values, considering the space wasting. Hence `char arr[3]` will take the same size as `char arr[4]`.

#### Indexing

Now we will figure out how the computer indexes an element in an array.

```c
void func() {
    int arr[10] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};

    int x = 1;
    int y = 2;

    int r = arr[1];
    r = arr[x];	
    r = arr[x+y];	
    r = arr[x*2+y];	
}
```

```c
// callee:
4:        int arr[10] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
0040D498 C7 45 D8 00 00 00 00 mov         dword ptr [ebp-28h],0
0040D49F C7 45 DC 01 00 00 00 mov         dword ptr [ebp-24h],1
0040D4A6 C7 45 E0 02 00 00 00 mov         dword ptr [ebp-20h],2
0040D4AD C7 45 E4 03 00 00 00 mov         dword ptr [ebp-1Ch],3
0040D4B4 C7 45 E8 04 00 00 00 mov         dword ptr [ebp-18h],4
0040D4BB C7 45 EC 05 00 00 00 mov         dword ptr [ebp-14h],5
0040D4C2 C7 45 F0 06 00 00 00 mov         dword ptr [ebp-10h],6
0040D4C9 C7 45 F4 07 00 00 00 mov         dword ptr [ebp-0Ch],7
0040D4D0 C7 45 F8 08 00 00 00 mov         dword ptr [ebp-8],8
0040D4D7 C7 45 FC 09 00 00 00 mov         dword ptr [ebp-4],9
5:
6:        int x = 1;
0040D4DE C7 45 D4 01 00 00 00 mov         dword ptr [ebp-2Ch],1
7:        int y = 2;
0040D4E5 C7 45 D0 02 00 00 00 mov         dword ptr [ebp-30h],2
8:
9:        int r = arr[1];
0040D4EC 8B 45 DC             mov         eax,dword ptr [ebp-24h]
0040D4EF 89 45 CC             mov         dword ptr [ebp-34h],eax
10:       r = arr[x];
// ebp-28h is the location of arr[0], or the base address of arr
// thereby it is indexed by base address + shift
0040D4F2 8B 4D D4             mov         ecx,dword ptr [ebp-2Ch]
0040D4F5 8B 54 8D D8          mov         edx,dword ptr [ebp+ecx*4-28h]
0040D4F9 89 55 CC             mov         dword ptr [ebp-34h],edx
11:       r = arr[x+y];
0040D4FC 8B 45 D4             mov         eax,dword ptr [ebp-2Ch]
0040D4FF 03 45 D0             add         eax,dword ptr [ebp-30h]
0040D502 8B 4C 85 D8          mov         ecx,dword ptr [ebp+eax*4-28h]
0040D506 89 4D CC             mov         dword ptr [ebp-34h],ecx
12:       r = arr[x*2+y];
0040D509 8B 55 D4             mov         edx,dword ptr [ebp-2Ch]
0040D50C 8B 45 D0             mov         eax,dword ptr [ebp-30h]
0040D50F 8D 0C 50             lea         ecx,[eax+edx*2]
0040D512 8B 54 8D D8          mov         edx,dword ptr [ebp+ecx*4-28h]
0040D516 89 55 CC             mov         dword ptr [ebp-34h],edx
```

Notice that the array is stored from low address to high address, meaning `arr[n-1]` is closest to `ebp`.

<EndMarkdown>