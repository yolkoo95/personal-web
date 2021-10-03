# Memory Management

## Table of Contents
- [Bit Operation](#bitoperation)
	- [Shift Operation](#shiftoperation)
	- [C Bit Operation](#cbitoperation)
	- [C Shift Operation](#cshiftoperation)
- [Header in C](#headerinc)
	- [Macro](#macro)
	- [Header File](#headerfile)
- [Dynamic Memory](#dynamicmemory)
	- [Allocation](#allocation)
	- [Initialization](#initialization)
	- [Free](#free)
- [File Operation](#fileoperation)
	- [Open and Close](#openandclose)
	- [Search](#search)
	- [Print](#print)
	- [Position](#position)
	- [Get](#get)
    - [Example](#example)

<TableEndMark>

## Bit Operation

In the C programming language, operations can be performed on a bit level using bitwise operators. Bitwise operations are contrasted by byte-level operations which characterize the bitwise operators' logical counterparts, the AND, OR and NOT operators. Instead of performing on individual bits, byte-level operators perform on strings of eight bits (known as bytes) at a time. The reason for this is that a byte is normally the smallest unit of addressable memory.

### Shift Operation

```c
// syntax for assembly language
[shift instruction] (register), imm
```

Shift instructions are summarized as follows,

| Operation | Description |
| :---: | :---: |
| SHL | logic shift left |
| SHR | logic shift right, 0 extension |
| SAL | arithmetic shift left |
| SAR | arithmetic shift right, sign extension |
| ROL | rotate left without carry |
| ROR | rotate right without carry |

The most/least significant bit will be stored into `CF` for left shift and right shift respectively. But there are two special instructions,

| Operation | Description |
| :---: | :---: |
| RCL | rotate left with carry |
| RCR | rotate right with carry |

Compared with `ROL` and `ROR`, it rotates with carry.

```bash
# rotate without carry
 ____       __ __ __ __ __ __ __ __
|_CF_| <-- |__|__|__|__|__|__|__|__| <---|
        |---------->---------------------|

# rotate with carry
 ____       __ __ __ __ __ __ __ __
|_CF_| <-- |__|__|__|__|__|__|__|__| <---|
  |---------------->---------------------|
```

### C Bit Operation

| Operation | Description |
| :---: | :---: |
| AND | `x & y`, 1101 & 1001 == 1001 |
| OR  | `x | y`, 1101 & 1001 == 1101 |
| NOT | `!x`, !1101 == 0010 |
| XOR | `x ^ y`, 1101 ^ 1001 == 0100 |

### C Shift Operation

```c
int main(int argc, char* argv[]) {
    // 0000 0000 0000 1000
    int i = 8;
    unsigned int ui = 8;

    // signed
    printf("%x\n", i << 1);
    printf("%x\n", i >> 1);
    // unsigned
    printf("%x\n", ui << 1);
    printf("%x\n", ui >> 1);

    return 0;
}
```

```c
// signed
8:        printf("%x\n", i << 1);
00401036 8B 45 FC             mov         eax,dword ptr [ebp-4]
00401039 D1 E0                shl         eax,1
0040103B 50                   push        eax
0040103C 68 1C 20 42 00       push        offset string "%x\n" (0042201c)
00401041 E8 7A 00 00 00       call        printf (004010c0)
00401046 83 C4 08             add         esp,8
9:        printf("%x\n", i >> 1);
00401049 8B 4D FC             mov         ecx,dword ptr [ebp-4]
// only effect in right shift
0040104C D1 F9                sar         ecx,1
0040104E 51                   push        ecx
0040104F 68 1C 20 42 00       push        offset string "%x\n" (0042201c)
00401054 E8 67 00 00 00       call        printf (004010c0)
00401059 83 C4 08             add         esp,8
10:       // unsigned
11:       printf("%x\n", ui << 1);
0040105C 8B 55 F8             mov         edx,dword ptr [ebp-8]
0040105F D1 E2                shl         edx,1
00401061 52                   push        edx
00401062 68 1C 20 42 00       push        offset string "%x\n" (0042201c)
00401067 E8 54 00 00 00       call        printf (004010c0)
0040106C 83 C4 08             add         esp,8
12:       printf("%x\n", ui >> 1);
0040106F 8B 45 F8             mov         eax,dword ptr [ebp-8]
00401072 D1 E8                shr         eax,1
00401074 50                   push        eax
00401075 68 1C 20 42 00       push        offset string "%x\n" (0042201c)
0040107A E8 41 00 00 00       call        printf (004010c0)
0040107F 83 C4 08             add         esp,8
```

Notice that there is no difference in left shift between signed and unsigned data.

## Header in C

Before we talk about header file, we will introduce macro definition (`#define`) first.

### Macro

The first question is how a program run?

```c
foo.c  -->  replace macro (#define) -->  compile (0x21)  --> link (header files) -->  executable binary file (.exe)
```

```c
// macro without arguments
#define TRUE 1
#define FALSE 0
#define PI 3.141592
#define DEBUG 1

// macro with arguments, arguments must enclosed by parentheses
#define MAX(A, B) ((A) > (B) ? (A) : (B))
#define MALLOC(n, type) ((type*)malloc((n) * sizeof(type)))
```

What's the advantages of making `MAX` as macro instead of a function? From the point of assembler, there is no need to allocate memory for a function call.

### Header File

A header file is a file with extension `.h` which contains C function declarations and macro definitions to be shared between several source files. There are two types of header files: the files that the programmer writes and the files that comes with your compiler.

```c
// foo.h
void foo();

// foo.c
void foo() {
  // statement;
}
```

```c
// main.c
#include "foo.h"

int main(int argc, char* argv[]) {
    foo();

    return 0;
}
```

PROBLEM: there is a scenario where a header file could be included repeatedly. How to fix it?

```c
#if !defined(filename_header)
#define filename_header

// if the version of microsoft compiler is greater than 1000, than use '#pragma once'
#if _MSC_VER > 1000
#pragma once
#endif

#endif
```

## Dynamic Memory

Since C is a structured language, it has some fixed rules for programming. One of it includes changing the size of an array. An array is collection of items stored at continuous memory locations.

```bash
 ___ ___ ___ ___ ___ ___ ___ ___ ___
|_1_|_2_|_4_|_8_|_1_|_2_|_4_|_8_|_1_|
  0   1   2   3   4   5   6   7   8
```

As it can be seen that the length (size) of the array above made is 9. But what if there is a requirement to change this length (size). What should we do? Then we have to resort to dynamic memory allocation. Notice that dynamic memory is in **heap space** of virtual memory.

### Allocation

REQUIRED, `<sdtlib.h>` and `<malloc.h>`

- `malloc`
`malloc` is used to allocate memory blocks.

```c
// typedef unsigned int size_t
void *malloc( size_t size );
```

```c
// allocate 4 int for ptr
int* ptr = (int*)malloc(sizeof(int) * 4);
```

### Initialization

- `memset`
`memset` sets buffers to a specified character.

```c
void *memset(void *str, int c, size_t n)
```

```c
// initialization
memset(ptr, 0, sizeof(int) * 4);
```

### Free

- `free`
`free` is used to deallocate or frees a memory block.

```c
void free( void *memblock );
```

```c
free(ptr);
ptr = NULL;
```

## File Operation

### Open and Close

- `fopen`
Each of these functions returns a pointer to the open file. A null pointer value indicates an error. 

| Mode | Description |
| :---: | :---: |
| r | Opens for reading. If the file does not exist or cannot be found, the `fopen` call fails. |
| w | Opens an empty file for writing. If the given file exists, its contents are destroyed. |
| a | Opens for writing at the end of the file (appending) WITHOUT removing the EOF marker before writing new data to the file; creates the file first if it doesn’t exist. |
| r+ | Opens for both reading and writing. (The file must exist) |
| w+ | Opens an empty file for both reading and writing. If the given file exists, its contents are destroyed. |
| a+ | Opens for reading and appending; the appending operation includes the removal of the EOF marker before new data is written to the file and the EOF marker is restored after writing is complete |

- `fclose`
fclose returns 0 if the stream is successfully closed. _fcloseall returns the total number of streams closed. Both functions return EOF to indicate an error.

```c
#include "stdio.h"

FILE *stream;

int main(int argc, char* argv[]) {
    int numclosed = 0;

    // open for read
    if ( (stream = fopen("data", "r")) == NULL ) {
        printf("The file 'data' was not found.\n");
    }
    else {
        printf("The file 'data' was opened.\n");
    }

    // open for write
    if ( (stream = fopen("data", "w+")) == NULL ) {
        printf("The file 'data' was not found.\n");
    }
    else {
        printf("The file 'data' was opened.\n");
    }

    // close file
    // noting the return rule of 'fclose'
    if ( fclose(stream) ) {
        printf("The file 'data' was not closed\n");
    }

    // close all other files
    numclosed = _fcloseall();
    printf("Number of files closed by _fcloseall: %u\n", numclosed);
}
```

### Search

- `fseek`
If successful, fseek returns 0. Otherwise, it returns a nonzero value. On devices incapable of seeking, the return value is undefined.

```c
int fseek( FILE *stream, long offset, int origin );
```

| Builtin Para. | Description |
| :---: | :---: |
| SEEK_CUR | current position of file pointer |
| SEEK_END | end of file |
| SEEK_SET | beginning of file |

```c
#include <stdio.h>

int main(int argc, char* argv[]) {
   FILE *stream;
   char line[81];
   int  result;

   stream = fopen( "fseek.out", "w+" );
   if( stream == NULL )
      printf( "The file fseek.out was not opened\n" );
   else {
      fprintf( stream, "The fseek begins here: "
                       "This is the file 'fseek.out'.\n" );
      // L means 'long'
      result = fseek( stream, 23L, SEEK_SET);
      if ( result )
         perror( "Fseek failed" );
      else {
         printf( "File pointer is set to middle of first line.\n" );
         fgets( line, 80, stream );
         printf( "%s", line );
      }
      fclose( stream );
   }
}
```

### Print

- `fprintf` or `fwprintf`
`fprintf` returns the number of bytes written. `fwprintf` returns the number of wide characters written. Each of these functions returns a **negative value** instead when an output error occurs. 

```c
int fprintf( FILE *stream, const char *format [, argument ]...);
```

```c
#include <stdio.h>
#include <process.h>

FILE *stream;

int main(int argc, char* argv[]) {
    int    i = 10;
    double fp = 1.5;
    char   s[] = "this is a string";
    char   c = '\n';

    stream = fopen( "fprintf.out", "w" );
    fprintf( stream, "%s%c", s, c );
    fprintf( stream, "%d\n", i );
    fprintf( stream, "%f\n", fp );
    fclose( stream );
    system( "type fprintf.out" );

    return 0;
}
```

```c
// Output:
this is a string
10
1.500000
```

### Position

- `ftell`
`ftell` is used to get the current position of a file pointer.

```c
long ftell( FILE *stream );
```

ftell returns the current file position. The value returned by ftell may not reflect the physical byte offset for streams opened in text mode, because text mode causes carriage return–linefeed translation.

```c
#include <stdio.h>

FILE *stream;

int main(int argc, char* argv[]) {
    long position;
    char list[100];
    if( (stream = fopen( "ftell.c", "rb" )) != NULL ) {
        /* Move the pointer by reading data: */
        fread( list, sizeof( char ), 100, stream );
        /* Get position after read: */
        position = ftell( stream );
        printf( "Position after trying to read 100 bytes: %ld\n",
                position );
        fclose( stream );
    }
}
```

```c
// Output:
Position after trying to read 100 bytes: 100
```

### Get

- `fgetc`
`fgetc` is used to read a character from a stream, which returns the character read as an int or return EOF to indicate an error or end of file.

```c
int fgetc( FILE *stream );
```

```c
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char* argv[]) {
    FILE *stream;
    char buffer[81];
    int  i, ch;

    /* Open file to read line from: */
    if( (stream = fopen( "fgetc.c", "r" )) == NULL ) {
        exit( 0 );
    }

    /* Read in first 80 characters and place them in "buffer": */
    ch = fgetc(stream);
    for (i = 0; (i < 80) && (feof(stream) == 0); i++) {
        buffer[i] = (char)ch;
        ch = fgetc( stream );
    }

    /* Add null to end string */
    buffer[i] = '\0';
    printf( "%s\n", buffer );
    fclose( stream );
}
```

- `fgets`
`fgets` is used to get a string from a stream, which returns string. NULL is returned to indicate an error or an end-of-file condition. Use `feof` or `ferror` to determine whether an error occurred.

BTW, `feof` function returns a nonzero value after the first read operation that attempts to read past the end of the file. It returns 0 if the current position is not end of file. There is no error return.

```c
char *fgets( char *string, int n, FILE *stream );
```

```c
int main(int argc, char* argv[]) {
   FILE *stream;
   char line[100];

   if( (stream = fopen( "fgets.c", "r" )) != NULL ) {
      if ( fgets( line, 100, stream ) == NULL)
         printf( "fgets error\n" );
      else
         printf( "%s", line );
      fclose( stream );
   }
}
```

### Example

Here we are going to read a file into memory.

```markdown
<!-- data.txt -->
123 123 123 123 123

<!-- binary code -->
            +0 +1 +2 +3 +4 +5 +6 +7 +8 +9 +A +B +C +D +E +F
0x00000000: 31 32 33 20 31 32 33 20 31 32 33 20 31 32 33 20 
0x00000010: 31 32 33

file size: 19 Bytes
```

```c
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define INT_T unsigned int
#define nullptr NULL

int main(int argc, char* argv[]) {
    FILE *stream;
	INT_T filesize = 0;
	char* file = nullptr;
	int i, ch;
	
	if ((stream = fopen("data.txt", "r")) != NULL) {
		// get file size
		fseek(stream, 0L, SEEK_END);
		filesize = ftell(stream);
		// reset stream pointer
		fseek(stream, 0L, SEEK_SET);

		// memory allocation and initialization
		file = (char*)malloc(sizeof(char) * filesize + 1);
		memset(file, 0, sizeof(char) * filesize + 1);

		// read stream to file
		ch = fgetc(stream);
		for (i = 0; (i < filesize); i++) {
			file[i] = (char)ch;
			ch = fgetc(stream);
		}
		file[filesize] = '\0';

		printf("Filesize: %d\n", filesize);
		printf("Length: %d\n", i);
		printf("%s\n", file);
	}
	else {
		printf("ERROR: The file was not opened properly.");
	}
}
```

<EndMarkdown>