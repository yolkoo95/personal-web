# C Language Seg.4

## Table of Contents
- [Switch](#switch)
	- [Syntax](#syntax)
	- [Switch and If-Else](#switchandif-else)
	- [Master Table](#mastertable)
	- [Auxiliary Table](#auxiliarytable)
- [While Loop](#whileloop)
	- [Syntax](#syntax)
	- [While-Do Loop](#while-doloop)
	- [Do-While Loop](#do-whileloop)
- [For Loop](#forloop)
	- [Syntax](#syntax)
	- [Assembly Analysis](#assemblyanalysis)

<TableEndMark>

## Switch

### Syntax

Switch is a powerful tool for soft development. Its basic syntax is as follow,

```c
switch (expression) {
case constant-expression:
    statement(s);
    break;
case constant-expression:
    statement(s);
    break;
...
...
case constant-expression:
    statement(s);
    break;
default:
    statement(s);
}
```

### Switch and If-Else

The first question is what's the differences between `switch` and `if-else`. Now let's have a try.

```c
#include "stdio.h"

void func(int var) {
	switch (var) {
	case 1:
		printf("1\n");
		break;
	case 3:
		printf("3\n");
		break;
	case 2:
		printf("2\n");
		break;
	default:
		printf("Error");
	}
}

int main(int argc, char* argv[]) {
	
	func(3);
	
	return 0;
}
```

Go into its assembly language.

```c
// caller:
21:       func(3);
004010E8 6A 03                push        3
004010EA E8 1B FF FF FF       call        @ILT+5(_func) (0040100a)
004010EF 83 C4 04             add         esp,4

// callee:
4:        switch (var) {
00401038 8B 45 08             mov         eax,dword ptr [ebp+8]
0040103B 89 45 FC             mov         dword ptr [ebp-4],eax
0040103E 83 7D FC 01          cmp         dword ptr [ebp-4],1
00401042 74 0E                je          func+32h (00401052)
00401044 83 7D FC 02          cmp         dword ptr [ebp-4],2
00401048 74 26                je          func+50h (00401070)
0040104A 83 7D FC 03          cmp         dword ptr [ebp-4],3
0040104E 74 11                je          func+41h (00401061)
00401050 EB 2D                jmp         func+5Fh (0040107f)
5:        case 1:
6:            printf("1\n");
00401052 68 2C 20 42 00       push        offset string "1\n" (0042202c)
00401057 E8 B4 00 00 00       call        printf (00401110)
0040105C 83 C4 04             add         esp,4
7:            break;
0040105F EB 2B                jmp         func+6Ch (0040108c)
8:        case 3:
9:            printf("3\n");
00401061 68 28 20 42 00       push        offset string "3\n" (00422028)
00401066 E8 A5 00 00 00       call        printf (00401110)
0040106B 83 C4 04             add         esp,4
10:           break;
0040106E EB 1C                jmp         func+6Ch (0040108c)
11:       case 2:
12:           printf("2\n");
00401070 68 24 20 42 00       push        offset string "2\n" (00422024)
00401075 E8 96 00 00 00       call        printf (00401110)
0040107A 83 C4 04             add         esp,4
13:           break;
0040107D EB 0D                jmp         func+6Ch (0040108c)
14:       default:
15:           printf("Error");
0040107F 68 1C 20 42 00       push        offset string "Error" (0042201c)
00401084 E8 87 00 00 00       call        printf (00401110)
00401089 83 C4 04             add         esp,4
16:       }
17:   }
```

It seems like that there is no difference between them in C or Assembly language. Now let's increase our cases to the extent that it will have more than 4 cases. (Of course, different assembler has different criteria)

### Master Table

```c
void func(int var) {
	switch (var) {
	case 1:
		printf("1\n");
		break;
	case 3:
		printf("3\n");
		break;
	case 2:
		printf("2\n");
		break;
    case 4:
        printf("4\n");
        break;
	default:
		printf("Error");
```

```c
4:        switch (var) {
0040D7B8 8B 45 08             mov         eax,dword ptr [ebp+8]
0040D7BB 89 45 FC             mov         dword ptr [ebp-4],eax
0040D7BE 8B 4D FC             mov         ecx,dword ptr [ebp-4]
0040D7C1 83 E9 01             sub         ecx,1
0040D7C4 89 4D FC             mov         dword ptr [ebp-4],ecx
0040D7C7 83 7D FC 03          cmp         dword ptr [ebp-4],3
0040D7CB 77 46                ja          $L349+0Fh (0040d813)
0040D7CD 8B 55 FC             mov         edx,dword ptr [ebp-4]
0040D7D0 FF 24 95 31 D8 40 00 jmp         dword ptr [edx*4+40D831h]
5:        case 1:
6:            printf("1\n");
0040D7D7 68 3C 21 42 00       push        offset string "1\n" (0042213c)
0040D7DC E8 2F 39 FF FF       call        printf (00401110)
0040D7E1 83 C4 04             add         esp,4
7:            break;
0040D7E4 EB 3A                jmp         $L349+1Ch (0040d820)
8:        case 3:
9:            printf("3\n");
0040D7E6 68 2C 20 42 00       push        offset string "3\n" (0042202c)
0040D7EB E8 20 39 FF FF       call        printf (00401110)
0040D7F0 83 C4 04             add         esp,4
10:           break;
0040D7F3 EB 2B                jmp         $L349+1Ch (0040d820)
11:       case 2:
12:           printf("2\n");
0040D7F5 68 28 20 42 00       push        offset string "2\n" (00422028)
0040D7FA E8 11 39 FF FF       call        printf (00401110)
0040D7FF 83 C4 04             add         esp,4
13:           break;
0040D802 EB 1C                jmp         $L349+1Ch (0040d820)
14:       case 4:
15:           printf("4\n");
0040D804 68 24 20 42 00       push        offset string "5\n" (00422024)
0040D809 E8 02 39 FF FF       call        printf (00401110)
0040D80E 83 C4 04             add         esp,4
16:           break;
0040D811 EB 0D                jmp         $L349+1Ch (0040d820)
17:       default:
18:           printf("Error");
0040D813 68 1C 20 42 00       push        offset string "Error" (0042201c)
0040D818 E8 F3 38 FF FF       call        printf (00401110)
0040D81D 83 C4 04             add         esp,4
19:       }

// master table
0040D831  D7 D7 40 00  // -> case 1
0040D835  F5 D7 40 00  // -> case 2
0040D839  E6 D7 40 00  // -> case 3
0040D83D  04 D8 40 00  // -> case 4
```

Surprisingly, the assembly version of switch is totally changed. There are some codes to explain.

- `edx*4+40D831h`: `0x0040D831` is a the base address of a table used by assembler to record addresses of various cases.
- `sub ecx,1`: why subtract 1 from `ecx`, we will explain it in next section.

In fact, switch use a master table to record addresses to jump so that `jcc`, which costs too many compute cycles, could be get rid off. However, there is a problem here -- space waste.

Let's see how master table waste space. What's difference between following switches?

```c
void func1(int var) {
	switch (var) {
	case 1:
		printf("1\n");
		break;
	case 3:
		printf("3\n");
		break;
	case 2:
		printf("2\n");
		break;
    case 4:
        printf("4\n");
        break;
    case 5:
        printf("5\n");
        break;
	default:
		printf("Error");
    }
}

void func2(int var) {
	switch (var) {
	case 1:
		printf("1\n");
		break;
	case 3:
		printf("3\n");
		break;
	case 2:
		printf("2\n");
		break;
    // case 4 has been deleted
    case 5:
        printf("5\n");
        break;
	default:
		printf("Error");
    }
}
```

```c
// the only difference is in master table
// func1:
0040D831  D7 D7 40 00  // -> case 1
0040D835  F5 D7 40 00  // -> case 2
0040D839  E6 D7 40 00  // -> case 3
0040D83D  04 D8 40 00  // -> case 4
0040D841  17 D8 40 00  // -> case 5
// func2:
0040D831  D7 D7 40 00  // -> case 1
0040D835  F5 D7 40 00  // -> case 2
0040D839  E6 D7 40 00  // -> case 3
0040D83D  31 D8 40 00  // -> case 4 is reserved but points to the address of default, causing space to be wasted.
0040D841  17 D8 40 00  // -> case 5
```

### Auxiliary Table

For assembler, switch with continuous cases is done by master table. However, if adopting the same strategy to switch with intermittent cases, it will cost too much space waste. Thereby, assembler resorts to **auxiliary table** to solve the problem.

```c
void func(int var) {
	switch (var) {
	case 22:
		printf("22\n");
		break;
	case 103:
		printf("103\n");
		break;
	case 2:
		printf("2\n");
		break;
    case 104:
        printf("104\n");
        break;
	default:
		printf("Error");
	}
}
```

```c
// caller:
004010E8 6A 16                push        16h
004010EA E8 1B FF FF FF       call        @ILT+5(_func) (0040100a)
004010EF 83 C4 04             add         esp,4

// callee:
4:        switch (var) {
0040D7B8 8B 45 08             mov         eax,dword ptr [ebp+8]
0040D7BB 89 45 FC             mov         dword ptr [ebp-4],eax
0040D7BE 8B 4D FC             mov         ecx,dword ptr [ebp-4]
// 2 is the minimum value of case
0040D7C1 83 E9 02             sub         ecx,2
0040D7C4 89 4D FC             mov         dword ptr [ebp-4],ecx
// 0x66 == 102, which is the maximum value minus the minimum value
// 104 - 2
0040D7C7 83 7D FC 66          cmp         dword ptr [ebp-4],66h
0040D7CB 77 4E                ja          $L349+0Fh (0040d81b)
0040D7CD 8B 45 FC             mov         eax,dword ptr [ebp-4]
0040D7D0 33 D2                xor         edx,edx
// (0040d84d)[eax] == (0040d84d+val(eax))
0040D7D2 8A 90 4D D8 40 00    mov         dl,byte ptr  (0040d84d)[eax]
0040D7D8 FF 24 95 39 D8 40 00 jmp         dword ptr [edx*4+40D839h]
5:        case 22:
6:            printf("22\n");
0040D7DF 68 B4 2F 42 00       push        offset string "1\n" (00422fb4)
0040D7E4 E8 27 39 FF FF       call        printf (00401110)
0040D7E9 83 C4 04             add         esp,4
7:            break;
0040D7EC EB 3A                jmp         $L349+1Ch (0040d828)
8:        case 103:
9:            printf("103\n");
0040D7EE 68 28 20 42 00       push        offset string "3\n" (00422028)
0040D7F3 E8 18 39 FF FF       call        printf (00401110)
0040D7F8 83 C4 04             add         esp,4
10:           break;
0040D7FB EB 2B                jmp         $L349+1Ch (0040d828)
11:       case 2:
12:           printf("2\n");
0040D7FD 68 AC 2F 42 00       push        offset string "102\n" (00422fac)
0040D802 E8 09 39 FF FF       call        printf (00401110)
0040D807 83 C4 04             add         esp,4
13:           break;
0040D80A EB 1C                jmp         $L349+1Ch (0040d828)
14:       case 104:
15:           printf("104\n");
0040D80C 68 B8 2F 42 00       push        offset string "104\n" (00422fb8)
0040D811 E8 FA 38 FF FF       call        printf (00401110)
0040D816 83 C4 04             add         esp,4
16:           break;
0040D819 EB 0D                jmp         $L349+1Ch (0040d828)
17:       default:
18:           printf("Error");
0040D81B 68 1C 20 42 00       push        offset string "Error" (0042201c)
0040D820 E8 EB 38 FF FF       call        printf (00401110)
0040D825 83 C4 04             add         esp,4
19:       }

// master table
0040D839  FD D7 40 00  // -> case 2
0040D83D  DF D7 40 00  // -> case 22
0040D841  EE D7 40 00  // -> case 103
0040D845  0C D8 40 00  // -> case 104
0040D849  1B D8 40 00  // -> default

// auxiliary table
0040D84D  00 04 04 04  ....
0040D851  04 04 04 04  ....
0040D855  04 04 04 04  ....
0040D859  04 04 04 04  ....
0040D85D  04 04 04 04  ....
0040D861  01 04 04 04  ....
0040D865  04 04 04 04  ....
0040D869  04 04 04 04  ....
0040D86D  04 04 04 04  ....
0040D871  04 04 04 04  ....
0040D875  04 04 04 04  ....
0040D879  04 04 04 04  ....
0040D87D  04 04 04 04  ....
0040D881  04 04 04 04  ....
0040D885  04 04 04 04  ....
0040D889  04 04 04 04  ....
0040D88D  04 04 04 04  ....
0040D891  04 04 04 04  ....
0040D895  04 04 04 04  ....
0040D899  04 04 04 04  ....
0040D89D  04 04 04 04  ....
0040D8A1  04 04 04 04  ....
0040D8A5  04 04 04 04  ....
0040D8A9  04 04 04 04  ....
0040D8AD  04 04 04 04  ....
0040D8B1  04 02 03 CC
```

Notice that master table is arranged in ascending order. In previous experiment, which has **continues cases** and **short distance between cases**, the assembler only uses a case table to index memory address to jump. For switch which has long distance between cases, it uses a case table along with an auxiliary table to index memory address to jump to save memory space. BTW, from `dl,byte ptr  (0040d84d)[eax]`, we could find out that distance between elements should be less than 256 in such scenario.

The idea of switch is also the tradeoff between speed and space.

- Speed: decrease the number of `jcc` instruction, which cost too much compute cycles.
- Space: for intermittent cases, use auxiliary table to save the space wasted by memory table.

To sum up, there are three versions of switch,

- If-Else-Like: for intermittent cases with long distance more than 256.
- Master Table Only: for continuous cases.
- Master Table and Auxiliary Table: for intermittent cases with short distance less than 256. 

## While Loop

There are two types of while loop -- do-while or while-do.

### Syntax

```c
// while-do
while (expression) {
	statement(s);
}

// do-while
do {
	statement(s);
} while (expression);
```

### While-Do Loop

We will also explore while loop by experiments.

```c
// this program will print numbers from 0 to 99
#include "stdio.h"

void func() {
	int i = 0;
	while (i < 100) {
		printf("%d\n", i);
		i++;
	}
}

int main(int argc, char* argv[]) {

	func();

	return 0;
}
```

```c
// callee:
4:        int i = 0;
00401038 C7 45 FC 00 00 00 00 mov         dword ptr [ebp-4],0
5:        while (i < 100) {
0040103F 83 7D FC 64          cmp         dword ptr [ebp-4],64h
00401043 7D 1C                jge         func+41h (00401061)
6:            printf("%d\n", i);
00401045 8B 45 FC             mov         eax,dword ptr [ebp-4]
00401048 50                   push        eax
00401049 68 1C 20 42 00       push        offset string "%d\n" (0042201c)
0040104E E8 6D 00 00 00       call        printf (004010c0)
00401053 83 C4 08             add         esp,8
7:            i++;
00401056 8B 4D FC             mov         ecx,dword ptr [ebp-4]
00401059 83 C1 01             add         ecx,1
0040105C 89 4D FC             mov         dword ptr [ebp-4],ecx
8:        }
0040105F EB DE                jmp         func+1Fh (0040103f)
9:    }
00401061 5F                   pop         edi
```

Assembly language for while-do is easy to understand. Let's sum it up.

```c
// while-do loop
cmp m, r/i   // <-- addr[cmp]
jcc addr[End]
...
loop body
...
jmp addr[cmp]

...          // <-- addr[End]
```

### Do-While Loop

What's different from while-do loop is that the loop body will be executed at least one time in do-while loop.

```c
// print numbers from 0 to 99
void func() {
	int i = 0;
    do {
		printf("%d\n", i);
		i++;
	} while (i < 100);
}
```

```c
4:        int i = 0;
00401038 C7 45 FC 00 00 00 00 mov         dword ptr [ebp-4],0
5:        do {
6:            printf("%d\n", i);
0040103F 8B 45 FC             mov         eax,dword ptr [ebp-4]
00401042 50                   push        eax
00401043 68 1C 20 42 00       push        offset string "%d\n" (0042201c)
00401048 E8 73 00 00 00       call        printf (004010c0)
0040104D 83 C4 08             add         esp,8
7:            i++;
00401050 8B 4D FC             mov         ecx,dword ptr [ebp-4]
00401053 83 C1 01             add         ecx,1
00401056 89 4D FC             mov         dword ptr [ebp-4],ecx
8:        } while(i < 100);
00401059 83 7D FC 64          cmp         dword ptr [ebp-4],64h
0040105D 7C E0                jl          func+1Fh (0040103f)
9:    }
0040105F 5F                   pop         edi
```

Notice that the philosophy of do-while is more similar to that of assembly language than while-do. Its assembly form could be summarized as follow,

```c
...            // <-- addr[Begin]
loop body
...
cmp m, r/i
jcc addr[Begin]
```

## For Loop

### Syntax

```c
for (initialization expr; test expr; update expr)
{    
     // body of the loop
     // statements we want to execute
}
```

### Assembly Analysis

We also make a for-loop version of program that prints number from 0 to 99.

```c
void func() {
	// notice that in C, the declaration of i should be out of for loop
	int i = 0;
	for (; i < 100; i++) {
		printf("%d\n", i);
	}
}
```

```c
4:        int i = 0;
00401038 C7 45 FC 00 00 00 00 mov         dword ptr [ebp-4],0
5:        for (; i < 100; i++) {
0040103F EB 09                jmp         func+2Ah (0040104a)
00401041 8B 45 FC             mov         eax,dword ptr [ebp-4]
00401044 83 C0 01             add         eax,1
00401047 89 45 FC             mov         dword ptr [ebp-4],eax
0040104A 83 7D FC 64          cmp         dword ptr [ebp-4],64h
0040104E 7D 13                jge         func+43h (00401063)
6:            printf("%d\n", i);
00401050 8B 4D FC             mov         ecx,dword ptr [ebp-4]
00401053 51                   push        ecx
00401054 68 1C 20 42 00       push        offset string "%d\n" (0042201c)
00401059 E8 72 00 00 00       call        printf (004010d0)
0040105E 83 C4 08             add         esp,8
7:        }
00401061 EB DE                jmp         func+21h (00401041)
```

It only take little efforts to master the structure of for loop. Let's sum it up.

```c
jmp addr[cmp] // for the first time
...
update expr   // <-- addr[update]
...
cmp m, r/i    // <-- addr[cmp]
jcc addr[End]
...
loop body
...
jmp addr[update]

...           // <-- addr[End]
...
```

<EndMarkdown>