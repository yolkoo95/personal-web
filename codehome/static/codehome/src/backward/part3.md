# C Language Seg.1

## Table of Contents
- [Calling Convension for x86](#callingconvensionforx86)
	- [CDECL](#cdecl)
	- [STDCALL and FASTCALL](#stdcallandfastcall)
- [Naked Function](#nakedfunction)
- [Data Type](#datatype)
- [Memory Layer](#memorylayer)
	- [Arguments Judgement](#argumentsjudgement)
- [IF Clause](#ifclause)
	- [If Then](#ifthen)
	- [If Else](#ifelse)
	- [If Else If](#ifelseif)

<TableEndMark>

## Calling Convension for x86

**Calling conventions** describe the interface of called code:

- The order in which atomic (scalar) parameters, or individual parts of a complex parameter, are allocated.
- How parameters are passed (pushed on the stack, placed in registers, or a mix of both).
- Which registers the called function must preserve for the caller (also known as: callee-saved registers or non-volatile registers).
- How the task of preparing the stack for, and restoring after, a function call is divided between the caller and the callee.

Calling conventions, type representations, and name mangling are all part of what is known as an application binary interface (ABI).

### CDECL 

The **cdecl (which stands for C declaration)** is a calling convention that originates from Microsoft's compiler for the C programming language and is used by many C compilers for the x86 architecture. In cdecl, subroutine arguments are passed on the stack. Integer values and memory addresses are returned in the EAX register. The cdecl calling convention is usually the default calling convention for x86 C compilers, although many compilers provide options to automatically change the calling conventions used.

- In the context of the C programming language, function arguments are *pushed on the stack* in the *right-to-left* order, i.e. the last argument is pushed first.
- Stack balance is the responsibility of caller, hence adecl is count as a member of `caller clean-up convention`.

```C
#include "stdio.h"

// same as `int __cdecl callee(int x, int y, int z)`
int callee(int x, int y, int z) {
	return x + y + z;
}

// same as `int __cdecl caller()`
int caller() {
	return callee(1, 2, 3) + 5;
}

void main(int argc, char* argv[]) {
	
	caller();

	return 0;
}
```

```C
// for caller
7:    int caller() {
00401070 55                   push        ebp
00401071 8B EC                mov         ebp,esp
00401073 83 EC 40             sub         esp,40h
00401076 53                   push        ebx
00401077 56                   push        esi
00401078 57                   push        edi
00401079 8D 7D C0             lea         edi,[ebp-40h]
0040107C B9 10 00 00 00       mov         ecx,10h
00401081 B8 CC CC CC CC       mov         eax,0CCCCCCCCh
00401086 F3 AB                rep stos    dword ptr [edi]
8:        return callee(1, 2, 3) + 5;
00401088 6A 03                push        3
0040108A 6A 02                push        2
0040108C 6A 01                push        1
0040108E E8 72 FF FF FF       call        @ILT+0(_callee) (00401005)
00401093 83 C4 0C             add         esp,0Ch
00401096 83 C0 05             add         eax,5
9:    }
00401099 5F                   pop         edi
0040109A 5E                   pop         esi
0040109B 5B                   pop         ebx
0040109C 83 C4 40             add         esp,40h
0040109F 3B EC                cmp         ebp,esp
004010A1 E8 5A 00 00 00       call        __chkesp (00401100)
004010A6 8B E5                mov         esp,ebp
004010A8 5D                   pop         ebp
004010A9 C3                   ret
```

```C
// for callee
3:    int callee(int x, int y, int z) {
00401030 55                   push        ebp
00401031 8B EC                mov         ebp,esp
00401033 83 EC 40             sub         esp,40h
00401036 53                   push        ebx
00401037 56                   push        esi
00401038 57                   push        edi
00401039 8D 7D C0             lea         edi,[ebp-40h]
0040103C B9 10 00 00 00       mov         ecx,10h
00401041 B8 CC CC CC CC       mov         eax,0CCCCCCCCh
00401046 F3 AB                rep stos    dword ptr [edi]
4:        return x + y + z;
00401048 8B 45 08             mov         eax,dword ptr [ebp+8]
0040104B 03 45 0C             add         eax,dword ptr [ebp+0Ch]
0040104E 03 45 10             add         eax,dword ptr [ebp+10h]
5:    }
00401051 5F                   pop         edi
00401052 5E                   pop         esi
00401053 5B                   pop         ebx
00401054 8B E5                mov         esp,ebp
00401056 5D                   pop         ebp
00401057 C3                   ret
```

### STDCALL and FASTCALL

**The stdcall calling convention** is a variation on the Pascal calling convention in which the callee is responsible for cleaning up the stack, but the parameters are pushed onto the stack in right-to-left order, as in the _cdecl calling convention. Registers EAX, ECX, and EDX are designated for use within the function. Return values are stored in the EAX register.

In the example, only part of critical segement will be presented.

```C
#include "stdio.h"

int __stdcall callee(int x, int y, int z) {
	return x + y + z;
}

int __stdcall caller() {
	return callee(1, 2, 3) + 5;
}

void main(int argc, char* argv[]) {
	
	caller();

	return 0;
}
```

```C
8:        return callee(1, 2, 3) + 5;
00401088 6A 03                push        3
0040108A 6A 02                push        2
0040108C 6A 01                push        1
// callee is responsible for balance stack
0040108E E8 86 FF FF FF       call        @ILT+20(_callee) (00401019)
00401093 83 C0 05             add         eax,5
```

```C
3:    int __stdcall callee(int x, int y, int z) {
00401030 55                   push        ebp
00401031 8B EC                mov         ebp,esp
00401033 83 EC 40             sub         esp,40h
00401036 53                   push        ebx
00401037 56                   push        esi
00401038 57                   push        edi
00401039 8D 7D C0             lea         edi,[ebp-40h]
0040103C B9 10 00 00 00       mov         ecx,10h
00401041 B8 CC CC CC CC       mov         eax,0CCCCCCCCh
00401046 F3 AB                rep stos    dword ptr [edi]
4:        return x + y + z;
00401048 8B 45 08             mov         eax,dword ptr [ebp+8]
0040104B 03 45 0C             add         eax,dword ptr [ebp+0Ch]
0040104E 03 45 10             add         eax,dword ptr [ebp+10h]
5:    }
00401051 5F                   pop         edi
00401052 5E                   pop         esi
00401053 5B                   pop         ebx
00401054 8B E5                mov         esp,ebp
00401056 5D                   pop         ebp
00401057 C2 0C 00             ret         0Ch  // important!!!
```

Microsoft **__fastcall convention (aka __msfastcall)** passes the first two arguments (evaluated left to right) that fit into ECX and EDX. Remaining arguments are pushed onto the stack from right to left. Also, callee takes task of balancing the stack. 

```C
#include "stdio.h"

int __fastcall callee(int x, int y, int z) {
	return x + y + z;
}

int __fastcall caller() {
	return callee(1, 2, 3) + 5;
}

void main(int argc, char* argv[]) {
	
	caller();

	return 0;
}
```

```C
8:        return callee(1, 2, 3) + 5;
// notice that the two arguments left most will be stored into registers edx and ecx respectively.
0040108A 6A 03                push        3
0040108C BA 02 00 00 00       mov         edx,2
00401091 B9 01 00 00 00       mov         ecx,1
00401096 E8 88 FF FF FF       call        @ILT+30(_callee@12) (00401023)
0040109B 83 C0 05             add         eax,5
```

```C
3:    int __fastcall callee(int x, int y, int z) {
00401030 55                   push        ebp
00401031 8B EC                mov         ebp,esp
00401033 83 EC 48             sub         esp,48h
00401036 53                   push        ebx
00401037 56                   push        esi
00401038 57                   push        edi
00401039 51                   push        ecx
0040103A 8D 7D B8             lea         edi,[ebp-48h]
0040103D B9 12 00 00 00       mov         ecx,12h
00401042 B8 CC CC CC CC       mov         eax,0CCCCCCCCh
00401047 F3 AB                rep stos    dword ptr [edi]
00401049 59                   pop         ecx
0040104A 89 55 F8             mov         dword ptr [ebp-8],edx
0040104D 89 4D FC             mov         dword ptr [ebp-4],ecx
4:        return x + y + z;
00401050 8B 45 FC             mov         eax,dword ptr [ebp-4]
00401053 03 45 F8             add         eax,dword ptr [ebp-8]
00401056 03 45 08             add         eax,dword ptr [ebp+8]
5:    }
00401059 5F                   pop         edi
0040105A 5E                   pop         esi
0040105B 5B                   pop         ebx
0040105C 8B E5                mov         esp,ebp
0040105E 5D                   pop         ebp
0040105F C2 04 00             ret         4
```

## Naked Function

For functions declared with the `naked` attribute, the compiler generates code without prolog and epilog code. You can use this feature to write your own prolog/epilog code sequences using inline assembler code. 

```C
// declspec stands for declare special
void __declspec(naked) func() {

}

// if programmer want to write assembly language in C, this is a desired feature
void __declspec(naked) func() {
    __asm {
        push ebp
        mov ebp,esp
        sub esp,0x40
        push ebx
        push esi
        push edi
        lea edi,dword ptr ds:[ebp-0x40]
        mov eax,CCCCCCCC
        mov ecx,0x10
        rep stosd
        // rep stos dword ptr es:[edi]

        pop edi
        pop esi
        pop ebx
        mov esp,ebp
        pop ebp
        
        ret
    }
}
```

## Data Type

There are four basic data type in C -- `char`, `short`, `int` and `long`, each of them has various data width in memory.

| Data Type | Bits | Bytes |
|:----:|:----:|:----:|
| char | 8 Bits | 1 Byte |
| short | 16 Bits | 2 Bytes |
| int | 32 Bits | 4 Bytes |
| long | 32 Bits | 4 Bytes |

There are two basic data category, signed or unsigned. In default, `char`, `short`, `int` and `long` mean `signed char`, `signed short`, `signed int`, `signed long`. For example, for an 8-bit-width data, the computer will interpret it as totally two value. 

```C
#include "stdio.h"

int main(int argc, char* argv[]) {

    char ch = 0xFF;
    unsigned uch = 0xFF;

    printf("%d \n %d", ch, uch);

    return 0;
}
```

```bash
Console Output:
-1
255
```

That's why we, as an instructor of a computer, have to be careful and responsible for how the data is interpreted with **TYPE CONTROL**.

Let's discuss it from assembly perspective.

```C
#include "stdio.h"

void myCompareSigned(int x, int y) {
    if (x < y) {
        printf("x < y");
    }
    else {
        printf("x > y");
    }
}

void myCompareUnsigned(unsigned int x, unsigned int y) {
    if (x < y) {
        printf("x < y");
    }
    else {
        printf("x > y");
    }
}

int main(int argc, char* argv[]) {

    myCompareSigned(1, 0xFF);
    myCompareUnsigned(1, 0xFF);

    return 0;
}
```

```C
// Although the data are interpreted as different thing, they are stored in same form.
23:       myCompareSigned(1, 0xFF);
00401108 68 FF 00 00 00       push        0FFh
0040110D 6A 01                push        1
0040110F E8 FB FE FF FF       call        @ILT+10(_myCompareSigned) (0040100f)
00401114 83 C4 08             add         esp,8

24:       myCompareUnsigned(1, 0xFF);
00401117 68 FF 00 00 00       push        0FFh
0040111C 6A 01                push        1
0040111E E8 E7 FE FF FF       call        @ILT+5(_myCompareUnsigned) (0040100a)
00401123 83 C4 08             add         esp,8
```

```C
// for myCompareSigned, using signed instuction jge(jump if greater and equal), remember that greater or less for signed number!
4:        if (x < y) {
00401048 8B 45 08             mov         eax,dword ptr [ebp+8]
0040104B 3B 45 0C             cmp         eax,dword ptr [ebp+0Ch]
0040104E 7D 0F                jge         myCompareSigned+2Fh (0040105f)
```

```C
// for myComparedUnsigned, using unsigned instruction jae(jump if above and equal), remember that above and below for unsigned!
13:       if (x < y) {
004010A8 8B 45 08             mov         eax,dword ptr [ebp+8]
004010AB 3B 45 0C             cmp         eax,dword ptr [ebp+0Ch]
004010AE 73 0F                jae         myCompareUnsigned+2Fh (004010bf)
```

## Memory Layer

Memory is divided into 5 parts roughly -- code part, stack, heap, global variable part, and constant part.

```bash
        |----------|
        |   Code   |    # <<===  readable and executable.
        |----------| 
        |          |    # <<===  readable and writable,
        |  Stack   |    # for temporary var, arguments
        |          |    # and buffer data
        |----------|
        |          |    
        |   Heap   |    # <<===  readable and writable, 
        |          |    # for dynamic allocation.
        |----------|
        |  Global  |    # <<===  readable and writable.
        | Variable |
        |----------|
        | Constant |    # <<===  read only.
        |----------|

```

- Global variables: are featured by a fixed address in code part, like `MOV reg, dword ptr ds:[0x0122ff7c]`, which is often called `base address`.
- Temporary variables: are stored into stack and discarded when the stack memory has been reclaimed, aka the calling is finished. Often, their addresses is `[ebp-4]`, `[ebp-8]` or `ebp-c` and so forth.

### Arguments Judgement

Here is an IMPORTANT question -- how to figure out how many arguments a function need by checking a segment of assembly code?

```c
// how many arguments in the function below?
00401050   push        ebp			
00401051   mov         ebp,esp			
00401053   sub         esp,48h		
00401056   push        ebx			
00401057   push        esi			
00401058   push        edi			
00401059   push        ecx    // backup ecx
0040105A   lea         edi,[ebp-48h]			
0040105D   mov         ecx,12h			
00401062   mov         eax,0CCCCCCCCh			
00401067   rep stos    dword ptr [edi]			
00401069   pop         ecx    // restore ecx
0040106A   mov         dword ptr [ebp-8],edx   // arg1		
0040106D   mov         dword ptr [ebp-4],ecx   // arg2			
00401070   mov         eax,dword ptr [ebp-4]			
00401073   add         eax,dword ptr [ebp-8]			
00401076   add         eax,dword ptr [ebp+8]   // arg3			
00401079   mov         [g_x (00427958)],eax	   // here is a global variable	
0040107E   pop         edi			
0040107F   pop         esi			
00401080   pop         ebx			
00401081   mov         esp,ebp			
00401083   pop         ebp			
00401084   ret         4			
```

There are some tips of how to find arguments.

- find those suspicious registers, which are used for transfer value. To be specific, we did not assign value to `ecx` in the function code, however `ecx` give its value to other `reg/memory`. for example, `dword ptr [ebp-8],edx`.  
- inner balance(`ret 4`) or outer balance(`add ebp, 4`).
- the # of arguments = # of registers used for transfer value + # of balance

## IF Clause

### If Then

Let's start with C code and analyze its assembly code.

```c
#include "stdio.h"

int z = 0;

void func1(int x, int y) {
	if (x > y) {
		z = x;
	}
}

int main(int argc, char* argv[]) {
	
	func1(1, 2);

	return 0;
}
```

```c
// stack preparation and reclaim are omitted.
6:        if (x > y) {
00401038 8B 45 08             mov         eax,dword ptr [ebp+8]
0040103B 3B 45 0C             cmp         eax,dword ptr [ebp+0Ch]
0040103E 7E 09                jle         func1+29h (00401049)
7:            z = x;
00401040 8B 4D 08             mov         ecx,dword ptr [ebp+8]
00401043 89 0D 50 7C 42 00    mov         dword ptr [_z (00427c50)],ecx
8:        }
00401049 5F                   pop         edi
```

Two things worth being discussed are how `if` works and how global variable is assigned.

- For a simple `if-then` clause, the system will affect flag registers by `cmp` and then use `jcc` to achieve controlling flow.
- The global variable CANNOT be assigned value by a word of memory directly. The process must be done with the help of a register, here is `ecx`.

*BTW, the condition in assembly is always opposite to that in C since the logic philosophy of assembly is different.*

### If Else

Now we have made some change to `func1` as follow.

```c
// only changed part is shown with respect to example above.
void func1(int x, int y) {
	if (x > y) {
		z = x;
	}
	else {
		z = y;
	}
}
```

What's the difference in assembly code?

```c
6:        if (x > y) {
00401038 8B 45 08             mov         eax,dword ptr [ebp+8]
0040103B 3B 45 0C             cmp         eax,dword ptr [ebp+0Ch]
0040103E 7E 0B                jle         func1+2Bh (0040104b)
7:            z = x;
00401040 8B 4D 08             mov         ecx,dword ptr [ebp+8]
00401043 89 0D 50 7C 42 00    mov         dword ptr [_z (00427c50)],ecx
8:        }
9:        else {
00401049 EB 09                jmp         func1+34h (00401054)
10:           z = y;
0040104B 8B 55 0C             mov         edx,dword ptr [ebp+0Ch]
0040104E 89 15 50 7C 42 00    mov         dword ptr [_z (00427c50)],edx
11:       }
14:   }
00401054 5F                   pop         edi
00401055 5E                   pop         esi
...
```

Two `jcc` command are critical here. Notice that the philosophy of  assembly language is to execute in sequential order, thereby its idea is to exclude other case by `jcc`, sorts of like a rule-out protocol. that explains why the condition in assembly code is always opposite to that in C.

At code address `00401049`, `jmp` jumps to the instruction to reclaim the stack since one case has done. Therefore, we could conclude that as follow,

```c
// if-else assembly conclusion
cmp var1, var2       // to affect eflag
jcc addr[case2]      // be always opposite to condition in C

....                 //-|
....                 // |-- case1
jmp addr[End]    //-|   BIG DIFFERENCE: jmp yes!

....                 //-|   <<--- the base address of case2
....                 // |-- case2, or else
....                 //-|

pop edi              //     <<--- the base address of End
....

// however in if-then, only 1 case
cmp var1, var2
jcc addr[End]
....                 //-|
....                 // |-- case
....                 //-|
                     //  BIG DIFFERENCE: no jmp!!! 
....                 //  <<--- the base of End address
```

Given knowledge above, let's try to analyse a segment of assembly code, the aim is to find how many global vars, temporary vars there are and if the function return any value, and what the code should be in C.

```c
0040D4A1 8B EC                mov         ebp,esp
0040D4A3 83 EC 48             sub         esp,48h
0040D4A6 53                   push        ebx
0040D4A7 56                   push        esi
0040D4A8 57                   push        edi
0040D4A9 8D 7D B8             lea         edi,[ebp-48h]
0040D4AC B9 12 00 00 00       mov         ecx,12h
0040D4B1 B8 CC CC CC CC       mov         eax,0CCCCCCCCh
0040D4B6 F3 AB                rep stos    dword ptr [edi]
0040D4B8 A1 50 7C 42 00       mov         eax,[_z (00427c50)]
0040D4BD 89 45 FC             mov         dword ptr [ebp-4],eax
0040D4C0 C7 45 F8 02 00 00 00 mov         dword ptr [ebp-8],2
0040D4C7 8B 4D 08             mov         ecx,dword ptr [ebp+8]
0040D4CA 3B 4D 0C             cmp         ecx,dword ptr [ebp+0Ch]
0040D4CD 7C 09                jl          func1+38h (0040d4d8)
0040D4CF 8B 55 F8             mov         edx,dword ptr [ebp-8]
0040D4D2 83 C2 01             add         edx,1
0040D4D5 89 55 F8             mov         dword ptr [ebp-8],edx
0040D4D8 8B 45 08             mov         eax,dword ptr [ebp+8]
0040D4DB 3B 45 0C             cmp         eax,dword ptr [ebp+0Ch]
0040D4DE 7D 0B                jge         func1+4Bh (0040d4eb)
0040D4E0 8B 4D F8             mov         ecx,dword ptr [ebp-8]
0040D4E3 89 0D 50 7C 42 00    mov         dword ptr [_z (00427c50)],ecx
0040D4E9 EB 0C                jmp         func1+57h (0040d4f7)
0040D4EB 8B 55 FC             mov         edx,dword ptr [ebp-4]
0040D4EE 03 55 F8             add         edx,dword ptr [ebp-8]
0040D4F1 89 15 50 7C 42 00    mov         dword ptr [_z (00427c50)],edx
0040D4F7 5F                   pop         edi
0040D4F8 5E                   pop         esi
0040D4F9 5B                   pop         ebx
0040D4FA 8B E5                mov         esp,ebp
0040D4FC 5D                   pop         ebp
0040D4FD C3                   ret
```

the answer is here,

```c
0040D4A1 8B EC                mov         ebp,esp
0040D4A3 83 EC 48             sub         esp,48h
0040D4A6 53                   push        ebx
0040D4A7 56                   push        esi
0040D4A8 57                   push        edi
0040D4A9 8D 7D B8             lea         edi,[ebp-48h]
0040D4AC B9 12 00 00 00       mov         ecx,12h
0040D4B1 B8 CC CC CC CC       mov         eax,0CCCCCCCCh
0040D4B6 F3 AB                rep stos    dword ptr [edi]
6:        int tmp1 = z;
0040D4B8 A1 50 7C 42 00       mov         eax,[_z (00427c50)]
0040D4BD 89 45 FC             mov         dword ptr [ebp-4],eax
7:        int tmp2 = 2;
0040D4C0 C7 45 F8 02 00 00 00 mov         dword ptr [ebp-8],2
8:
9:        if (x >= y) {
0040D4C7 8B 4D 08             mov         ecx,dword ptr [ebp+8]
0040D4CA 3B 4D 0C             cmp         ecx,dword ptr [ebp+0Ch]
0040D4CD 7C 09                jl          func1+38h (0040d4d8)
10:           tmp2 = tmp2 + 1;
0040D4CF 8B 55 F8             mov         edx,dword ptr [ebp-8]
0040D4D2 83 C2 01             add         edx,1
0040D4D5 89 55 F8             mov         dword ptr [ebp-8],edx
11:       }
12:
13:       if (x < y) {
0040D4D8 8B 45 08             mov         eax,dword ptr [ebp+8]
0040D4DB 3B 45 0C             cmp         eax,dword ptr [ebp+0Ch]
0040D4DE 7D 0B                jge         func1+4Bh (0040d4eb)
14:           z = tmp2;
0040D4E0 8B 4D F8             mov         ecx,dword ptr [ebp-8]
0040D4E3 89 0D 50 7C 42 00    mov         dword ptr [_z (00427c50)],ecx
15:       }
16:       else {
0040D4E9 EB 0C                jmp         func1+57h (0040d4f7)
17:           z = tmp1 + tmp2;
0040D4EB 8B 55 FC             mov         edx,dword ptr [ebp-4]
0040D4EE 03 55 F8             add         edx,dword ptr [ebp-8]
0040D4F1 89 15 50 7C 42 00    mov         dword ptr [_z (00427c50)],edx
18:       }
19:   }
0040D4F7 5F                   pop         edi
0040D4F8 5E                   pop         esi
0040D4F9 5B                   pop         ebx
0040D4FA 8B E5                mov         esp,ebp
0040D4FC 5D                   pop         ebp
0040D4FD C3                   ret
```

### If Else If

Similarly we have made some change to `func1` as follow.

```c
// only changed part is shown with respect to example above.
void func1(int x, int y, int z) {
	if (x > y) {
		r = x;
	}
	else if (y > z) {
		r = y;
	}
    else if (z > x) {
        r = z;
    }
    else {
        r = 1;
    }
}
```

Let's figure out what's the feature of multi-if-else.

```c
...
6:        if (x > y) {
0040D4B8 8B 45 08             mov         eax,dword ptr [ebp+8]
0040D4BB 3B 45 0C             cmp         eax,dword ptr [ebp+0Ch]
0040D4BE 7E 0B                jle         func1+2Bh (0040d4cb)
7:            r = x;
0040D4C0 8B 4D 08             mov         ecx,dword ptr [ebp+8]
0040D4C3 89 0D 50 7C 42 00    mov         dword ptr [_r (00427c50)],ecx
8:        }
9:        else if (y > z) {
0040D4C9 EB 2F                jmp         func1+5Ah (0040d4fa)
0040D4CB 8B 55 0C             mov         edx,dword ptr [ebp+0Ch]
0040D4CE 3B 55 10             cmp         edx,dword ptr [ebp+10h]
0040D4D1 7E 0A                jle         func1+3Dh (0040d4dd)
10:           r = y;
0040D4D3 8B 45 0C             mov         eax,dword ptr [ebp+0Ch]
0040D4D6 A3 50 7C 42 00       mov         [_r (00427c50)],eax
11:       }
12:       else if (z > x) {
0040D4DB EB 1D                jmp         func1+5Ah (0040d4fa)
0040D4DD 8B 4D 10             mov         ecx,dword ptr [ebp+10h]
0040D4E0 3B 4D 08             cmp         ecx,dword ptr [ebp+8]
0040D4E3 7E 0B                jle         func1+50h (0040d4f0)
13:           r = z;
0040D4E5 8B 55 10             mov         edx,dword ptr [ebp+10h]
0040D4E8 89 15 50 7C 42 00    mov         dword ptr [_r (00427c50)],edx
14:       }
15:       else {
0040D4EE EB 0A                jmp         func1+5Ah (0040d4fa)
16:           r = 1;
0040D4F0 C7 05 50 7C 42 00 01 mov         dword ptr [_r (00427c50)],1
17:       }
18:   }
0040D4FA 5F                   pop         edi
...
```

Notice that multi-if-else is easy to find when we have mastered if-then and if-else. There are some features as follow,

- a COMMON `End`, `jmp addr[END]`, appears in all `else-if` cases, since only one of all cases will happen.
- at beginning of a case, there always be a new `cmp` and `jcc` instruction which is mirror to `else-if`.
- in the last case, aka `else`, there is no `cmp` or `jcc`, which is same as `else` in `if-else`.

```c
// if-else-if assembly conclusion
cmp var1, var2       // to affect eflag
jcc addr[case2]      // be always opposite to condition in C

....                 //-|
....                 // |-- case1
jmp addr[End]        //-|   BIG DIFFERENCE: jmp yes!

cmp var1, var2       //-|   <<--- the base address of case2
jcc addr[case3]      // |-- case2
....                 // |
jmp addr[End]        //-|

cmp var1, var2       //-|   <<--- the base address of case3
jcc addr[case4]      // |-- case3
....                 // |
jmp addr[End]        //-|

....
....

cmp var1, var2       //-|   <<--- the base address of caseN-1
jcc addr[caseN]      // |-- caseN-1
....                 // |
jmp addr[End]        //-|

....                 //-|   <<--- the base address of caseN
....                 // |-- caseN, or else
....                 //-|

pop edi              //     <<--- the base address of End
....

```



<EndMarkdown>