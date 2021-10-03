# C Language Seg.3

## Table of Contents
- [Multi-dimension Array](#multi-dimensionarray)
	- [Initialization](#initialization)
	- [Indexing](#indexing)
- [Struct](#struct)
	- [Initialization](#initialization)
	- [Struct as Argument](#structasargument)
	- [Struct as Return Value](#structasreturnvalue)
- [Word Alignment](#wordalignment)
	- [Sizeof](#sizeof)
	- [Data Alignment](#dataalignment)
		- [Alignment Configuration](#alignmentconfiguration)

<TableEndMark>

## Multi-dimension Array

To give us an intuition about how a 2-d array is stored in the memory, let's compare two arrays with same size. (We will use 2-d array to stand for N-d array)

```c
void twoDArray() {
    int arr[3][4] = {
        {1, 2, 3, 4},
        {5, 6, 7, 8},
        {9, 10, 11, 12}
    };
}

void oneDArray() {
    int arr[12] = {
        1, 2, 3, 4, 5, 6,
        7, 8, 9, 10, 11, 12
    };
}
```

```c
// twoDArray:
00401030 55                   push        ebp
00401031 8B EC                mov         ebp,esp
00401033 83 EC 70             sub         esp,70h
00401036 53                   push        ebx
00401037 56                   push        esi
00401038 57                   push        edi
00401039 8D 7D 90             lea         edi,[ebp-70h]
0040103C B9 1C 00 00 00       mov         ecx,1Ch
00401041 B8 CC CC CC CC       mov         eax,0CCCCCCCCh
00401046 F3 AB                rep stos    dword ptr [edi]
4:        int arr[3][4] = {
5:            {1, 2, 3, 4},
00401048 C7 45 D0 01 00 00 00 mov         dword ptr [ebp-30h],1
0040104F C7 45 D4 02 00 00 00 mov         dword ptr [ebp-2Ch],2
00401056 C7 45 D8 03 00 00 00 mov         dword ptr [ebp-28h],3
0040105D C7 45 DC 04 00 00 00 mov         dword ptr [ebp-24h],4
6:            {5, 6, 7, 8},
00401064 C7 45 E0 05 00 00 00 mov         dword ptr [ebp-20h],5
0040106B C7 45 E4 06 00 00 00 mov         dword ptr [ebp-1Ch],6
00401072 C7 45 E8 07 00 00 00 mov         dword ptr [ebp-18h],7
00401079 C7 45 EC 08 00 00 00 mov         dword ptr [ebp-14h],8
7:            {9, 10, 11, 12}
00401080 C7 45 F0 09 00 00 00 mov         dword ptr [ebp-10h],9
00401087 C7 45 F4 0A 00 00 00 mov         dword ptr [ebp-0Ch],0Ah
0040108E C7 45 F8 0B 00 00 00 mov         dword ptr [ebp-8],0Bh
00401095 C7 45 FC 0C 00 00 00 mov         dword ptr [ebp-4],0Ch
8:        };

// oneDArray:
004010C0 55                   push        ebp
004010C1 8B EC                mov         ebp,esp
004010C3 83 EC 70             sub         esp,70h
004010C6 53                   push        ebx
004010C7 56                   push        esi
004010C8 57                   push        edi
004010C9 8D 7D 90             lea         edi,[ebp-70h]
004010CC B9 1C 00 00 00       mov         ecx,1Ch
004010D1 B8 CC CC CC CC       mov         eax,0CCCCCCCCh
004010D6 F3 AB                rep stos    dword ptr [edi]
12:       int arr[12] = {
13:           1, 2, 3, 4, 5, 6,
004010D8 C7 45 D0 01 00 00 00 mov         dword ptr [ebp-30h],1
004010DF C7 45 D4 02 00 00 00 mov         dword ptr [ebp-2Ch],2
004010E6 C7 45 D8 03 00 00 00 mov         dword ptr [ebp-28h],3
004010ED C7 45 DC 04 00 00 00 mov         dword ptr [ebp-24h],4
004010F4 C7 45 E0 05 00 00 00 mov         dword ptr [ebp-20h],5
004010FB C7 45 E4 06 00 00 00 mov         dword ptr [ebp-1Ch],6
14:           7, 8, 9, 10, 11, 12
00401102 C7 45 E8 07 00 00 00 mov         dword ptr [ebp-18h],7
00401109 C7 45 EC 08 00 00 00 mov         dword ptr [ebp-14h],8
00401110 C7 45 F0 09 00 00 00 mov         dword ptr [ebp-10h],9
00401117 C7 45 F4 0A 00 00 00 mov         dword ptr [ebp-0Ch],0Ah
0040111E C7 45 F8 0B 00 00 00 mov         dword ptr [ebp-8],0Bh
15:       };
```

It turns out to be the same allocation for two seemingly different array! Therefore, from assembler's perspective, 1-D array has no difference from 2-d array.

### Initialization

What will happen if user only give part of elements values.

```c
void twoDArray() {
    int arr[3][4] = {
        {1, 2},
        {5},
        {9, 10, 11, 12}
    };
}

// filling blank position with zero
5:        int arr[3][4] = {
6:            {1, 2},
00401048 C7 45 D0 01 00 00 00 mov         dword ptr [ebp-30h],1
0040104F C7 45 D4 02 00 00 00 mov         dword ptr [ebp-2Ch],2
00401056 33 C0                xor         eax,eax
00401058 89 45 D8             mov         dword ptr [ebp-28h],eax
0040105B 89 45 DC             mov         dword ptr [ebp-24h],eax
7:            {5},
0040105E C7 45 E0 05 00 00 00 mov         dword ptr [ebp-20h],5
00401065 33 C9                xor         ecx,ecx
00401067 89 4D E4             mov         dword ptr [ebp-1Ch],ecx
0040106A 89 4D E8             mov         dword ptr [ebp-18h],ecx
0040106D 89 4D EC             mov         dword ptr [ebp-14h],ecx
8:            {9, 10, 11, 12}
00401070 C7 45 F0 09 00 00 00 mov         dword ptr [ebp-10h],9
00401077 C7 45 F4 0A 00 00 00 mov         dword ptr [ebp-0Ch],0Ah
0040107E C7 45 F8 0B 00 00 00 mov         dword ptr [ebp-8],0Bh
00401085 C7 45 FC 0C 00 00 00 mov         dword ptr [ebp-4],0Ch
```

If following code could be compiled? Thinking from assembler's perspective.

```c
void twoDArray() {
    int arr[][4] = {
        {1, 2},
        {5},
        {9, 10, 11, 12}
    };

    // or
    int arr2[][4] = {
        1, 2, 3, 4, 5, 6, 7, 8, 9
    };
}
```

The answer is YES, 'cause assembler will know that every group has 4 elements. What's different is that assembler has to calculate what's the number of higher dimension according to the number of initialization elements.

```c
// arr:
5:        int arr[][4] = {
6:            {1, 2},
00401048 C7 45 D0 01 00 00 00 mov         dword ptr [ebp-30h],1
0040104F C7 45 D4 02 00 00 00 mov         dword ptr [ebp-2Ch],2
00401056 33 C0                xor         eax,eax
00401058 89 45 D8             mov         dword ptr [ebp-28h],eax
0040105B 89 45 DC             mov         dword ptr [ebp-24h],eax
7:            {5},
0040105E C7 45 E0 05 00 00 00 mov         dword ptr [ebp-20h],5
00401065 33 C9                xor         ecx,ecx
00401067 89 4D E4             mov         dword ptr [ebp-1Ch],ecx
0040106A 89 4D E8             mov         dword ptr [ebp-18h],ecx
0040106D 89 4D EC             mov         dword ptr [ebp-14h],ecx
8:            {9, 10, 11, 12}
00401070 C7 45 F0 09 00 00 00 mov         dword ptr [ebp-10h],9
00401077 C7 45 F4 0A 00 00 00 mov         dword ptr [ebp-0Ch],0Ah
0040107E C7 45 F8 0B 00 00 00 mov         dword ptr [ebp-8],0Bh
00401085 C7 45 FC 0C 00 00 00 mov         dword ptr [ebp-4],0Ch

// arr2:
5:        int arr2[][4] = {
6:            1, 2, 3, 4, 5, 6, 7, 8, 9
00401048 C7 45 D0 01 00 00 00 mov         dword ptr [ebp-30h],1
0040104F C7 45 D4 02 00 00 00 mov         dword ptr [ebp-2Ch],2
00401056 C7 45 D8 03 00 00 00 mov         dword ptr [ebp-28h],3
0040105D C7 45 DC 04 00 00 00 mov         dword ptr [ebp-24h],4
00401064 C7 45 E0 05 00 00 00 mov         dword ptr [ebp-20h],5
0040106B C7 45 E4 06 00 00 00 mov         dword ptr [ebp-1Ch],6
00401072 C7 45 E8 07 00 00 00 mov         dword ptr [ebp-18h],7
00401079 C7 45 EC 08 00 00 00 mov         dword ptr [ebp-14h],8
7:        };
00401080 C7 45 F0 09 00 00 00 mov         dword ptr [ebp-10h],9
00401087 33 C0                xor         eax,eax
00401089 89 45 F4             mov         dword ptr [ebp-0Ch],eax
0040108C 89 45 F8             mov         dword ptr [ebp-8],eax
0040108F 89 45 FC             mov         dword ptr [ebp-4],eax
```

### Indexing

The next topic is how assembler index an element of a 2-d array.

```c
void twoDArray() {
    int x = 1;
    int y = 2;

    int arr2[][4] = {
        1, 2, 3, 4, 5, 6, 7, 8, 9
    };

    printf("%d", arr2[x][y]);
}
```

```c
5:        int x = 1;
0040D848 C7 45 FC 01 00 00 00 mov         dword ptr [ebp-4],1
6:        int y = 2;
0040D84F C7 45 F8 02 00 00 00 mov         dword ptr [ebp-8],2
7:        int arr2[][4] = {
8:            1, 2, 3, 4, 5, 6, 7, 8, 9
0040D856 C7 45 C8 01 00 00 00 mov         dword ptr [ebp-38h],1
0040D85D C7 45 CC 02 00 00 00 mov         dword ptr [ebp-34h],2
0040D864 C7 45 D0 03 00 00 00 mov         dword ptr [ebp-30h],3
0040D86B C7 45 D4 04 00 00 00 mov         dword ptr [ebp-2Ch],4
0040D872 C7 45 D8 05 00 00 00 mov         dword ptr [ebp-28h],5
0040D879 C7 45 DC 06 00 00 00 mov         dword ptr [ebp-24h],6
0040D880 C7 45 E0 07 00 00 00 mov         dword ptr [ebp-20h],7
0040D887 C7 45 E4 08 00 00 00 mov         dword ptr [ebp-1Ch],8
9:        };
0040D88E C7 45 E8 09 00 00 00 mov         dword ptr [ebp-18h],9
0040D895 33 C0                xor         eax,eax
0040D897 89 45 EC             mov         dword ptr [ebp-14h],eax
0040D89A 89 45 F0             mov         dword ptr [ebp-10h],eax
0040D89D 89 45 F4             mov         dword ptr [ebp-0Ch],eax
10:
11:       printf("%d", arr2[x][y]);
0040D8A0 8B 4D FC             mov         ecx,dword ptr [ebp-4]
// ecx from 0x00000001 to 0x00000010
0040D8A3 C1 E1 04             shl         ecx,4
// or
// 0040D8A3 6B C9 14          imul        ecx,ecx,10h
0040D8A6 8D 54 0D C8          lea         edx,[ebp+ecx-38h]
0040D8AA 8B 45 F8             mov         eax,dword ptr [ebp-8]
0040D8AD 8B 0C 82             mov         ecx,dword ptr [edx+eax*4]
0040D8B0 51                   push        ecx
0040D8B1 68 0C 21 42 00       push        offset string "%d" (0042210c)
0040D8B6 E8 F5 FE FF FF       call        printf (0040d7b0)
0040D8BB 83 C4 08             add         esp,8
```

Notice that from `0x0040D8A0` to `0x0040D8A6`, the assembler calculate higher dimension, namely `x`. `shl ecx,4` means it has been moved 2^4 bytes, which is 4 int wide given a lower dimension group has 4 elements. In other word, it has jumped over x groups of elements. Thereby, edx then saves the address of `arr2[1][0]` by `lea edx,[ebp+ecx-38h]`. Then from `0x0040D8AA` to `0040D8AD`, it only calculate the shift on target group by `edx+eax*4`. From C perspective, `arr2[1][0] = arr2[1*4 + 0]`, the latter arr2 is a 1-d array. All in all, the indexing could be concluded as `x * # of a group * size of element + y * size of element`. 

## Struct

### Initialization

Struct is a type of C and used for packaging a lot of elements with different types.

```c
// less common definition
struct foo {
    type argv1;
    type argv2;
    type argv3;
    ...
}var1, ..., varN;

// often define struct as a type and use it
typedef struct foo {
    type argv1;
    type argv2;
    type argv3;
    ...
} Foo;

Foo var1, var2, ...;
```

Now let's see how a struct works in memory.

```c
#include "stdio.h"
typedef struct Account {
    int passwd;
    short age;
    char gender;
} Account;

Account russo; // <--- a global variable

void initializerOfAccount(int o_passwd, short o_age, char o_gender) {
    russo.passwd = o_passwd;
    russo.age = o_age;
    russo.gender = o_gender;
}

int main(int argc, char* argv[]) {
    initializerOfAccount(123456, 24, 'F');
}
```

```c
// caller:
19:       initializerOfAccount(123456, 24, 'F');
00401088 6A 46                push        46h
0040108A 6A 18                push        18h
0040108C 68 40 E2 01 00       push        1E240h
00401091 E8 6F FF FF FF       call        @ILT+0(_initializerOfAccount) (00401005)
00401096 83 C4 0C             add         esp,0Ch

// callee:
13:       russo.passwd = o_passwd;
00401038 8B 45 08             mov         eax,dword ptr [ebp+8]
0040103B A3 30 7E 42 00       mov         [_russo (00427e30)],eax
14:       russo.age = o_age;
00401040 66 8B 4D 0C          mov         cx,word ptr [ebp+0Ch]
00401044 66 89 0D 34 7E 42 00 mov         word ptr [_russo+4 (00427e34)],cx
15:       russo.gender = o_gender;
0040104B 8A 55 10             mov         dl,byte ptr [ebp+10h]
0040104E 88 15 36 7E 42 00    mov         byte ptr [_russo+6 (00427e36)],dl
```

Notice that similar to array, struct searches address by base address(`00427e30`) plus offset, `[_russo+4 (00427e34)]`. Since `russo` is a global variable, it has a predefined memory block.

### Struct as Argument

Different from builtin type, the size of struct may be bigger than that of one or more registers. How is a struct transferred as an argument?

```c
void foo(Account account) {

}

int main(int argc, char* argv[]) {
    initializerOfAccount(123456, 24, 'F');
	foo(russo);
}
```

```c
// caller:
24:       foo(russo);
0040D4D9 A1 34 7E 42 00       mov         eax,[_russo+4 (00427e34)]
0040D4DE 50                   push        eax
0040D4DF 8B 0D 30 7E 42 00    mov         ecx,dword ptr [_russo (00427e30)]
0040D4E5 51                   push        ecx
0040D4E6 E8 24 3B FF FF       call        @ILT+10(_foo) (0040100f)
0040D4EB 83 C4 08             add         esp,8

// callee: nothing except normal operation
```

What interests us is that struct `Account` should take up 7 bytes(4 for `int`, 2 for `short` and 1 for `char`). However, the assembler use two registers `eax` and `ecx` (for 8 bytes) to transfer it. Why? It is similar to `char arr[3]`, the assembler will align data width to machine width, x86 for 4 bytes and x86_64 for 8 bytes. *Data alignment* is a tradeoff between speed and space.

Now let's see what will happen when a struct contains a large bunch of elements with same kind?

```c
typedef struct Foo{
    int a;
    int b;
    int c;
    int d;
    int e;
    int f;
} Foo;

void structAsArgument(Foo foo) {

}

int main(int argc, char* argv[]) {
    Foo foo;
    foo.a = 1;
    foo.b = 2;
    foo.c = 3;
    foo.d = 4;
    foo.e = 5;
    foo.f = 6;

    structAsArgument(foo);
}
```

```c
// caller: same as array, from high low address to high address
17:       Foo foo;
18:       foo.a = 1;
00401058 C7 45 E8 01 00 00 00 mov         dword ptr [ebp-18h],1
19:       foo.b = 2;
0040105F C7 45 EC 02 00 00 00 mov         dword ptr [ebp-14h],2
20:       foo.c = 3;
00401066 C7 45 F0 03 00 00 00 mov         dword ptr [ebp-10h],3
21:       foo.d = 4;
0040106D C7 45 F4 04 00 00 00 mov         dword ptr [ebp-0Ch],4
22:       foo.e = 5;
00401074 C7 45 F8 05 00 00 00 mov         dword ptr [ebp-8],5
23:       foo.f = 6;
0040107B C7 45 FC 06 00 00 00 mov         dword ptr [ebp-4],6
24:
25:       structAsArgument(foo);
// movs: memory to memory, substitute for push
00401082 83 EC 18             sub         esp,18h
00401085 B9 06 00 00 00       mov         ecx,6
0040108A 8D 75 E8             lea         esi,[ebp-18h]
0040108D 8B FC                mov         edi,esp
0040108F F3 A5                rep movs    dword ptr [edi],dword ptr [esi]
00401091 E8 7E FF FF FF       call        @ILT+15(_initializerOfAccount) (00401014)
00401096 83 C4 18             add         esp,18h
```

If there are a lot of elements with same kind, assembler will push them in a clever way, which is sort of like buffer initialization.

### Struct as Return Value

Now Let's discuss case of struct as return value;

```c
Foo structAsReturnValue() {
	Foo foo;
    foo.a = 1;
    foo.b = 2;
    foo.c = 3;
    foo.d = 4;
    foo.e = 5;
    foo.f = 6;

	return foo;
}

int main(int argc, char* argv[]) {
   
    Foo foo = structAsReturnValue();

	return 0;
}
```

```c
// caller:
27:       Foo foo = structAsReturnValue();
// it is caller's responsibility to reserve space for return value
00401058 8D 45 D0             lea         eax,[ebp-30h]
0040105B 50                   push        eax
0040105C E8 B8 FF FF FF       call        @ILT+20(_structAsReturnValue) (00401019)
00401061 83 C4 04             add         esp,4
00401064 8B F0                mov         esi,eax
00401066 B9 06 00 00 00       mov         ecx,6
0040106B 8D 7D E8             lea         edi,[ebp-18h]
0040106E F3 A5                rep movs    dword ptr [edi],dword ptr [esi]

// callee:
21:       return foo;
0040D4F2 B9 06 00 00 00       mov         ecx,6
0040D4F7 8D 75 E8             lea         esi,[ebp-18h]
// [ebp+8] is eax of caller
0040D4FA 8B 7D 08             mov         edi,dword ptr [ebp+8]
0040D4FD F3 A5                rep movs    dword ptr [edi],dword ptr [esi]
0040D4FF 8B 45 08             mov         eax,dword ptr [ebp+8]
```

`eax` plays an important role for two things: 1. reserve space in caller function and record the base address of `tmp`; 2. tell callee function where to put return value. There are two `rep movs` assignments,

```c
// caller:  
|--------|   //  <--- ebp-30h, base addr of tmp,
|  tmp   |   //    used for receive return value    
|--------|   //  <--- ebp-18h, base addr of foo
|  foo   | 
|--------|
|  ebp   |   // the second assignment: movs foo, tmp
|--------|
|  ...   |

// callee:
|--------|
|  foo   |   // the first assignment: movs tmp, foo
|--------|
|  ebp   |    
```

## Word Alignment

### Sizeof

- `sizeof`
`sizeof` is a builtin function in C language to print the size of a variable.

```c
void printSize() {
    // print the size of array
    char arr_ch[10];
    int arr_int[10];
    printf("%d\n", sizeof(arr_ch));
    printf("%d\n", sizeof(arr_int));

    // print the size of customized struct
    typedef struct foo {
        char ch;
        int n;
        char ch2;
    } Foo;

    typedef struct foo1 {
        int n;
        char ch;
        char ch2;
    } Foo1;

    printf("%d\n", sizeof(Foo));
    printf("%d\n", sizeof(Foo1));
}

// builtin type has to be printed in main function
int main(int argc, char* argv[]) {
    // print the size of builtin type
    printf("%d\n", sizeof(char));
    printf("%d\n", sizeof(short));
    printf("%d\n", sizeof(int));
    printf("%d\n", sizeof(long int));
    printf("%d\n", sizeof(__int64));
    printf("%d\n", sizeof(float));
    printf("%d\n", sizeof(double));

    printSize();
}
```

```c
// Output:
// builtin -->
1
2
4
4
8
4
8
// arr -->
10
40
// struct --> !!!
12
8
```

Surprisingly, the same structs just with elements in different order will have different size! That's caused by what we call **Word Alignment**.

### Data Alignment

The CPU in modern computer hardware performs reads and writes to memory most efficiently when the data is naturally aligned, which generally means that the data's memory address is a multiple of the data size. For instance, in a 32-bit architecture, the data may be aligned if the data is stored in four consecutive bytes and the first byte lies on a 4-byte boundary.

Data alignment is the aligning of elements according to their natural alignment. To ensure natural alignment, it may be necessary to insert some padding between structure elements or after the last element of a structure. For example, on a 32-bit machine, a data structure containing a 16-bit value followed by a 32-bit value could have 16 bits of padding between the 16-bit value and the 32-bit value to align the 32-bit value on a 32-bit boundary. Alternatively, one can pack the structure, omitting the padding, which may lead to slower access, but uses three quarters as much memory.

For more reading, [data structure alignment](https://en.wikipedia.org/wiki/Data_structure_alignment)

#### Alignment Configuration

- `#pragma pack(n)`
`#pragma pack(n)` is unused to declare how many bytes are used to align, 8 by default.

```c
// syntax:
#pragma pack(n)
struct foo() {
    
};
#pragma pack()
```

Let's take an example,

```c
// 4 bytes alignment
#pragma pack(4)
struct test {
    int a;
    __int64 b;
    char ch;
}
#pragma pack()
```

```bash
# memory stack of 4 bytes alignment
# where an means nth byte of variable a
    +0   +1   +2   +3
  |----|----|----|----|
  | a1 | a2 | a3 | a4 |     addr(low)
  |----|----|----|----|        |
  |----|----|----|----|        |
  | b1 | b2 | b3 | b4 |     addr(high)  
  |----|----|----|----|
  |----|----|----|----| 
  | b5 | b6 | b7 | b8 |  
  |----|----|----|----|
  |----|----|----|----| 
  | ch | 00 | 00 | 00 |  
  |----|----|----|----|

# memory stack of 2 bytes alignment
    +0   +1  
  |----|----|
  | a1 | a2 |
  |----|----|
  |----|----|
  | a3 | a4 |
  |----|----|
  |----|----|
  | b1 | b2 |
  |----|----|
  |----|----|
  | b3 | b4 |
  |----|----|
  |----|----|
  | b5 | b6 |
  |----|----|
  |----|----|
  | b7 | b8 |
  |----|----|
  |----|----|
  | ch | 00 |
  |----|----|

# memory stack of 8 bytes alignment
    +0   +1   +2   +3   +4   +5   +6   +7
  |----|----|----|----|----|----|----|----| 
  | a1 | a2 | a3 | a4 | 00 | 00 | 00 | 00 | 
  |----|----|----|----|----|----|----|----|
  |----|----|----|----|----|----|----|----| 
  | b1 | b2 | b3 | b4 | b5 | b6 | b7 | b8 | 
  |----|----|----|----|----|----|----|----|
  |----|----|----|----|----|----|----|----| 
  | ch | 00 | 00 | 00 | 00 | 00 | 00 | 00 | 
  |----|----|----|----|----|----|----|----|
```

Now let's solve the problem before,

```c
// 8 bytes alignment
typedef struct foo {
    char ch1;        // takes 1 byte, padding 3 bytes
    int n;           // takes 4 bytes
    char ch2;        // takes 1 byte, padding 3 bytes
} Foo;

typedef struct foo1 {
    int n;           // takes 4 bytes
    char ch1;        // takes 1 bytes
    char ch2;        // takes 1 bytes padding 2 bytes
} Foo1;
```

```bash
# Foo: although the struct takes 16 bytes, however 4 bytes as a group, the last 4 bytes are available for other use, thereby it takes 12 bytes
    +0   +1   +2   +3   +4   +5   +6   +7
  |----|----|----|----|----|----|----|----| 
  |ch1 | 00 | 00 | 00 | n1 | n2 | n3 | n4 | 
  |----|----|----|----|----|----|----|----|
  |----|----|----|----|----|----|----|----| 
  |ch2 | 00 | 00 | 00 | cc | cc | cc | cc | 
  |----|----|----|----|----|----|----|----|

## this is a wrong memory arrangement for Foo !!! for 4-byte int, it only takes either half of 8 bytes group
    +0   +1   +2   +3   +4   +5   +6   +7
  |----|----|----|----|----|----|----|----| 
  |ch1 | n1 | n2 | n3 | n4 | 00 | 00 | 00 | 
  |----|----|----|----|----|----|----|----|
  |----|----|----|----|----|----|----|----| 
  |ch2 | 00 | 00 | 00 | cc | cc | cc | cc | 
  |----|----|----|----|----|----|----|----|

# Foo1:
   +0   +1   +2   +3   +4   +5   +6   +7
  |----|----|----|----|----|----|----|----| 
  | n1 | n2 | n3 | n4 |ch1 |ch2 | 00 | 00 | 
  |----|----|----|----|----|----|----|----|
```

Think of the memory arrangement of this struct, which will give you an intuition about how memory allocate space to variable.

```c
typedef struct foo {
    char ch;
    short a;
    int b;
}Foo;
```

```bash
# 8 bytes by default
    +0   +1   +2   +3   +4   +5   +6   +7
  |----|----|----|----|----|----|----|----| 
  | ch | 00 | a1 | a2 | b1 | b2 | b3 | b4 | 
  |----|----|----|----|----|----|----|----|
```

Two principles here are important:

- the offset must be the multiple of size of data waiting to be stored. eg. after `char`, `short` must be stored at address with 2n, or `int` be at address with 4n.
- the total size of a struct will be the multiple of the largest size of data type in that struct, NOT the multiple of pack size, which explains why following struct takes `12 bytes = 3 * sizeof(int)`.

```c
// 8 bytes alignment
typedef struct foo {
    char ch1;        // takes 1 byte, padding 3 bytes
    int n;           // takes 4 bytes
    char ch2;        // takes 1 byte, padding 3 bytes
} Foo;
```

To sum up, the idea of word alignment is tradeoff between speed(the rate of searching memory address) and space(ratio of used memory to allocated memory).

BTW, `typedef` is used to define a new type or name.

```c
// define an array with 10 int elements termed as vector
typedef int vector[10];

// define a Class type
typedef struct class {
    int classNum;
    char* headMaster;
    int totalStudents;
} Class;
```
<EndMarkdown>