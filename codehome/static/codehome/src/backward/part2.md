# Stack Memory Analysis

## Table of Contents
- [How does computer call a function](#howdoescomputercallafunction)
- [Memory Attack and Add Shell](#memoryattackandaddshell)
	- [Memory Attack](#memoryattack)
	- [Add Shell](#addshell)
- [Recursive Calling](#recursivecalling)

<TableEndMark>

## How does computer call a function

Let's start with an example of drawing C program, which calls a simple function, from memory perspective.

```C
#include "stdio.h"

int addTwo(int a, int b) {
    int c = 2;

    return a + b + c;
}

int main(int argc, char* argv[]) {
    int result = plus(3, 4);

    return 0;
}
```

then translate C code into assembly language

```C
// what happened in main function
9:        int r = addTwo(3, 4);
00401078   push        4
0040107A   push        3
0040107C   call        @ILT+0(_addTwo) (00401005)
00401081   add         esp,8
00401084   mov         dword ptr [ebp-4],eax
10:
11:       return 0;
00401087   xor         eax,eax

// the secret in addTwo()
00401005   jmp         addTwo (00401020)

00401020   push        ebp
00401021   mov         ebp,esp
00401023   sub         esp,44h
00401026   push        ebx
00401027   push        esi
00401028   push        edi
00401029   lea         edi,[ebp-44h]
0040102C   mov         ecx,11h
00401031   mov         eax,0CCCCCCCCh
00401036   rep stos    dword ptr [edi]
4:        int z = 2;
00401038   mov         dword ptr [ebp-4],2
5:        return x + y + z;
0040103F   mov         eax,dword ptr [ebp+8]
00401042   add         eax,dword ptr [ebp+0Ch]
00401045   add         eax,dword ptr [ebp-4]
6:    }
00401048   pop         edi
00401049   pop         esi
0040104A   pop         ebx
0040104B   mov         esp,ebp
0040104D   pop         ebp
0040104E   ret
```

Now let's figure out what happens in the stack when every assembly instruction is executed,

![Push Arguments](codehome/src/img/backward/fig-1.png)

When calling a function, the first thing the computer will do is to push the arguments into memory stack(`push 4; push 3`), then it will call the function(`call @ILT+0(_addTwo) (00401005)`). `CALL` instruction will do two things -- push **return address** and modify `EIP` to calling address. Then the machine will execute the instruction with address `EIP` points to, which is `JMP` serving as a bridge linking outside and inside of a function.

![Allocation of New Stack](codehome/src/img/backward/fig-2.png)

In second phase, the computer is going to allocate new stack memory for function being called. First it will `push EBP` to save old bottom, and `mov EBP, ESP` to elevate the bottom of stack to the top.
then it will allocate new space by `SUB ESP, 0x44`.

![Backup and Initialization](codehome/src/img/backward/fig-3.png)

In order to not intervene the status of old stack, like registers and EFLAGS, the computer will backup some important arguments(`push EBX; push ESI; push EDI`). Then it will initialize buffer, which is allocated just now, to `0xCCCCCCCC`, which is `int32` serving as breakpoints.

![Function](codehome/src/img/backward/fig-4.png)

Computer will save local variable into buffer(`mov dword ptr ss:[EBP-4], 2`), and record the result of operation into `EAX`, which will take the result back to outer function.

![Restore and Destroy Stack](codehome/src/img/backward/fig-5.png)

After finishing calculation, the computer will restore status of outer function(`pop EDI; pop ESI; pop EBX`), and lower `ESP`(`mov ESP, EBP`).
And then give `EBP` its original value, which is the address of the bottom of stack of outer function. At last `RET` instruction will `pop return address ` to `EIP` so that system is able to know how to go back to right location.

![Outer Balance](codehome/src/img/backward/fig-6.png)

Finally to keep original status, the computer has to balance the arguments by(`add ESP, 8`) to get rid of 2 arguments, which is `3` and `4`.

- `EBP + 4` is a super important memory address.
- Data in buffer will remain there although they are NOT in current stack, therefore INITIALIZATION is citical.

## Memory Attack and Add Shell

### Memory Attack

There are two simple attack programs using the knowledge above, what will happen when the program is executed?

```C
// TIPS: arr[6] is the address of `EBP+4`

#include "stdio.h"

void Attack() {
	while (1) {
		printf("Attacking!!!\n");
	}
}

int main(int argc, char* argv[]) {
	int arr[5] = {0};
	arr[6] = (int)Attack;

	return 0;
}
```

```C
// TIPS: a[10] is the address of i 

#include "stdio.h"

void printHelloWorld() {
	int i = 0;
	int a[] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};

	for (i = 0; i <= 10; i++) {
		a[i] = 0;  // when i == 10, `a[10] = 0;` has the same effect as `i = 0;`.
		printf("Hello World!\n");
	}
}

int main(int argc, char* argv[])
{
	printHelloWorld();

	return 0;
}
```

### Add Shell

The idea is that all codes will be interpreted as binary code. As a function could be hard coded as binary code, we could translate our function that we don't want other to know into binary code and call it by function pointer, which is a efficient way from being attacked by hackers.

```C
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

```C
// TIPS: add sheild to our programs, size of char is 1 byte

#include "stdio.h"

unsigned char func[] = 
{
    0x55, 0x8B, 0xEC, 0x83, 0xEC, 0x54, 0xC0, 0xE5, 0xCC, 0xBE,
    0x67, 0x01, 0xDF, 0x7F, 0xB8, 0xE2, 0xEC, 0x54, 0xC0, 0xE5,
    0x2C, 0xE3, 0xEE, 0x7B, 0x2R, 0xE3, 0xC4, 0x77, 0x04, 0x2B
}

typedef int *(pfunc)(int x, int y);

int main(int argc, char* argv[]) {
    pfunc pf = (pfunc)&func;
    printf("%x", pf(3, 4));
    
    return 0;
}
```

## Recursive Calling

Let's analyze stack calling of a recursive function,

```C
#include "stdio.h"

int factorial(int n) {
	if (n == 0) {
		return 1;
	}

	return n * factorial(n - 1);
}


int main(int argc, char* argv[]) {
	
	int n = factorial(3);

	return 0;
}
```
First let's see what's happening in main function. 

```C
12:   int main(int argc, char* argv[]) {
// allocate new space for main function
00401080 55                   push        ebp      
00401081 8B EC                mov         ebp,esp
00401083 83 EC 44             sub         esp,44h
// protect related registers
00401086 53                   push        ebx
00401087 56                   push        esi
00401088 57                   push        edi
// initialize buffer
00401089 8D 7D BC             lea         edi,[ebp-44h]
0040108C B9 11 00 00 00       mov         ecx,11h
00401091 B8 CC CC CC CC       mov         eax,0CCCCCCCCh
00401096 F3 AB                rep stos    dword ptr [edi]
13:
14:       int n = factorial(3);
// push args and out-function balance
00401098 6A 03                push        3
0040109A E8 66 FF FF FF       call        @ILT+0(_factorial) (00401005)
0040109F 83 C4 04             add         esp,4
// give the result to local variable n
004010A2 89 45 FC             mov         dword ptr [ebp-4],eax
15:
16:       return 0;
// clear the eflag register
004010A5 33 C0                xor         eax,eax
17:   }
// restore related registers
004010A7 5F                   pop         edi
004010A8 5E                   pop         esi
004010A9 5B                   pop         ebx
// check if stack is balanced
004010AA 83 C4 44             add         esp,44h
004010AD 3B EC                cmp         ebp,esp
004010AF E8 1C 00 00 00       call        __chkesp (004010d0)
// lower stack
004010B4 8B E5                mov         esp,ebp
004010B6 5D                   pop         ebp
004010B7 C3                   ret
```

To figure out how the recursive function works, we need to step into the call function `@00401005`

```C
3:    int factorial(int n) {
// as usual, allacation of new stack
00401020 55                   push        ebp
00401021 8B EC                mov         ebp,esp
00401023 83 EC 40             sub         esp,40h
00401026 53                   push        ebx
00401027 56                   push        esi
00401028 57                   push        edi
00401029 8D 7D C0             lea         edi,[ebp-40h]
0040102C B9 10 00 00 00       mov         ecx,10h
00401031 B8 CC CC CC CC       mov         eax,0CCCCCCCCh
00401036 F3 AB                rep stos    dword ptr [edi]

// the codes indicating the true function
4:        if (n == 0) {
00401038 83 7D 08 00          cmp         dword ptr [ebp+8],0
// noting that assembly language often write the condition opposite to C condition, == -> jne
0040103C 75 07                jne         factorial+25h (00401045)
5:            return 1;
0040103E B8 01 00 00 00       mov         eax,1
00401043 EB 15                jmp         factorial+3Ah (0040105a)
6:        }
7:
8:        return n * factorial(n - 1);
00401045 8B 45 08             mov         eax,dword ptr [ebp+8]
00401048 83 E8 01             sub         eax,1
0040104B 50                   push        eax
// the function here is calling itself!!!
0040104C E8 B4 FF FF FF       call        @ILT+0(_factorial) (00401005)
00401051 83 C4 04             add         esp,4
// [ebp+8] is n in current level of calling
00401054 8B 4D 08             mov         ecx,dword ptr [ebp+8]
00401057 0F AF C1             imul        eax,ecx
9:    }
0040105A 5F                   pop         edi
0040105B 5E                   pop         esi
0040105C 5B                   pop         ebx

// checking if balance
0040105D 83 C4 40             add         esp,40h
00401060 3B EC                cmp         ebp,esp
00401062 E8 69 00 00 00       call        __chkesp (004010d0)

// lower stack
00401067 8B E5                mov         esp,ebp
00401069 5D                   pop         ebp
0040106A C3                   ret
```

From a holistic perspective, the change of stack looks like this,

![changes of the stack of recursive function](codehome/src/img/backward/recursive-function.png)

<EndMarkdown>