# PE Seg.2

## Table of Contents
- [Union](#union)
- [Section Table](#sectiontable)
	- [Structure](#structure)
	- [Location](#location)
- [Parser for Section Table](#parserforsectiontable)

<TableEndMark>

## Union

A union is a special data type available in C that allows to store different data types in the same memory location. You can define a union with many members, but only one member can contain a value at any given time. Unions provide an efficient way of using the same memory location for multiple-purpose.

```c
// definition
union TYPENAME {
    mem1;
    mem2;
    ...
} VAR1, VAR2, ...;
```

```c
// shared memory
#include <stdio.h>
#include <string.h>
 
union Data {
   int i;
   float f;
   char str[20];
};
 
int main(int argc, char* argv[]) {
   union Data data;        

   printf( "Memory size occupied by data : %d\n", sizeof(data));

   return 0;
}
```

```c
// Output:
20
```

Notice that the size of union is the maximum size among its elements.

One useful way to use union is print memory in different formats. Remember in last note, union could be used to save memory in different ways.

```c
#include <stdio.h>
#include <stdlib.h>

union ImageElement{
    unsigned int dword;
    char memory[4];
};

void printElement(char* prompt, union ImageElement *pEle) {
	int i;

    printf(prompt);
    printf("\n");
    
    // print with big endian
    for (i = 0; i < 4; i++) {
		printf("%02x ", pEle->memory[i]);
	}
    printf("\n");

    // print in Int format
    printf("%x\n", pEle->dword);
}

int main(int argc, char* argv[]) {
	union ImageElement Magic;
	char buffer[4] = { 0x4c, 0x12, 0x40, 0x00 };
    memcpy(&Magic.memory, buffer, sizeof(buffer));

    // save in either way, and print in the other format
	// Magic.dword = 0x0040124c;
    printElement("Magic: ", &Magic);
}
```

```c
// Output:
Magic:
4c 12 40 00
40124c
```

BTW, a common pitfall is that people are always confused about what the shared memory means. Compare following code with one above, and be careful to nuances of two codes.

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

union ImageElement{
    unsigned int dword;
    char* memory;
};

void printElement(char* prompt, union ImageElement *pEle) {
	unsigned int i;

    printf(prompt);
    printf("\n");
    
    // print with big endian
    for (i = 0; i < 4; i++) {
		printf("%02x ", pEle->memory[i]);
	}
    printf("\n");

    // print in Int format
    printf("%x\n", pEle->dword);
}

int main(int argc, char* argv[]) {
	union ImageElement Magic;
	char* memory;
	char buffer[4] = { 0x4c, 0x12, 0x40, 0x00 };

	memory = (char*)malloc(sizeof(char) * sizeof(buffer));
	memset(memory, 0, sizeof(buffer));
    memcpy(memory, buffer, sizeof(buffer));
	Magic.memory = memory;
	memory = NULL;

	// Magic.dword = 0x0040124c;
    printElement("Magic: ", &Magic);
}
```

```c
// Output:
Magic:
4c 12 40 00
3707a8 // the address of pointer
```

In the first code, shared memory means the value of variable. However in the second one, what shared memory saved is the address or pointer, not the value of memory that we want to show.

## Section Table

### Structure

Section Table is like a catalog of sections, which contains information describing overall features of a section. Each description is formalized as a structure termed IMAGE_SECTION_HEADER.

```c
#define IMAGE_SIZEOF_SHORT_NAME 8

typedef struct _IMAGE_SECTION_HEADER {
    BYTE  Name[IMAGE_SIZEOF_SHORT_NAME];
    union {
        DWORD PhysicalAddress;
        DWORD VirtualSize;
    } Misc;
    DWORD VirtualAddress;
    DWORD SizeOfRawData;
    DWORD PointerToRawData;
    DWORD PointerToRelocations;
    DWORD PointerToLinenumbers;
    WORD  NumberOfRelocations;
    WORD  NumberOfLinenumbers;
    DWORD Characteristics;
} IMAGE_SECTION_HEADER, *PIMAGE_SECTION_HEADER;
```

| Members | Description | 
| :---: | :---: |
| Name | An 8-byte, null-padded UTF-8 string. There is no terminating null character if the string is exactly eight characters long. |
| Misc.PhysicalAddress | The file address. |
| Misc.VirtualSize | The total size of the section when loaded into memory, in bytes. If this value is greater than the SizeOfRawData member, the section is filled with zeroes. |
| VirtualAddress | The address of the first byte of the section when loaded into memory, relative to the image base. |
| SizeOfRawData | The size of the initialized data on disk, in bytes. This value must be a multiple of the FileAlignment member of the IMAGE_OPTIONAL_HEADER structure. |
| PointerToRawData | A file pointer to the first page within the PE file. This value must be a multiple of the FileAlignment member of the IMAGE_OPTIONAL_HEADER structure. |
| PointerToRelocations | A file pointer to the beginning of the relocation entries for the section. DEBUG |
| PointerToLinenumbers | A file pointer to the beginning of the line-number entries for the section. DEBUG |
| NumberOfRelocations | The number of relocation entries for the section. DEBUG |
| NumberOfLinenumbers | The number of line-number entries for the section. DEBUG |
| Characteristics | The characteristics of the image. |

There is some details worthy of discussing,

- How to parse `Name`:
As we known, name of a section is an 8-byte, null-padded (or padded) string. If user do not give a name to a section, the system will assign a random name to it. However a random name is dangerous. For example, if system give a string `elephant`, and we save it in a char array with 8 elements, there will be no place for termination flag `\0`. Therefore, we often do it as follows,

```c
// parse name in a secure way
char[9] name = {0};
memcpy(&name, addr[Name], 8);
name[8] = '\0';
```

- Misc
Misc is a union variable, which contains two members. These two members are same internally. `PhysicalAddress` refers to the real size in file buffer or disks, and `VirtualSize` refers to the real size in virtual memory. These two values are same.

```bash
# real size means from 5B to E0
# physical storage
    00 00 00 00 00 00  ----------|
    00 00 00 00 00 00            |
    00 00 00 00 00 00            |--> PointerToRawData
    ...                          |
    5B 45 21 41 58 00  ---| -----|
    81 2C 1F 11 28 82     |
    39 12 11 01 00 01     |    A Section
    27 82 E0 00 00 00     |--> SizeOfRawData 
    00 00 00 00 00 00     |  (File Alignment)
    00 00 00 00 00 00     |
    00 00 00 00 00 00  ---|
    ...
    next section

# virtual memory
    00 00 00 00 00 00  -----------------|  --> ImageBase
    00 00 00 00 00 00                   |
    00 00 00 00 00 00                   |
    00 00 00 00 00 00                   |--> VirtualAddress
    ...                ---|             |
    00 00 00 00 00 00     |--> Stretch  |
    ...                ---|             |
    5B 45 21 41 58 00  ---|  -----------|
    81 2C 1F 11 28 82     |
    39 12 11 01 00 01     |   
    27 82 E0 00 00 00     |--> A Section
    00 00 00 00 00 00     |  (Memory Alignment)
    00 00 00 00 00 00     |
    00 00 00 00 00 00     |
    ...                ---|             
    00 00 00 00 00 00     |--> Stretch 
    ...                ---| 
    ...                ---|
    5B 45 21 41 58 00     |--> Next Section
    ...                ---|
```

- Characteristic
Values defined for characteristics of sections are as follows,

| Value | Description |
| :---: | :---: |
| 0x00000020 | The section contains executable code. |
| 0x00000040 | The section contains initialized data. |
| 0x00000080 | The section contains uninitialized data. |
| 0x00000200 | The section contains comments or other information. This is valid only for object files. | 
| 0x00000800 | The section will not become part of the image. This is valid only for object files. |
| 0x00001000 | The section contains COMDAT data. This is valid only for object files. |
| 0x00004000 | Reset speculative exceptions handling bits in the TLB entries for this section. |
| 0x00008000 | The section contains data referenced through the global pointer. | 
| 0x00100000 | Align data on a 1-byte boundary. |
| 0x04000000 | The section cannot be cached. |
| 0x08000000 | The section cannot be paged. |
| 0x10000000 | The section can be shared in memory. |
| 0x20000000 | The section can be executed as code. |
| 0x40000000 | The section can be read. |
| 0x80000000 | The section can be written to. |

where readable, writable and executable are three critical characteristics.

### Location

After learning the structure of a section, the next thing we need talk about is how to locate section table.

There are some important size we have to remember,

| Variable | Value |
| :---: | :---: |
| DOS Size | 0x40, or 64 |
| DOSHeader.e_lfanew | NT Header offset, 0xE0 in general |
| PE Size | 0x14, or 20 |
| Optional PE Size | equals to SizeOfOptionalHeader, 0xE0 for 32-bit and 0xF0 for 64-bit |
| SizeOfOptionalHeader | a member of File Header, 0xE0 for 32-bit |
| NumberOfSections | a member of File Header |

```bash
# PE Structure in File Buffer Review
00 1B 9D 29 20 11  ---|
12 2D 3C 87 7C 01     |
...                   |---> DOS Header
...      e_lfanew  ---|
09 00 12 C0 00 1D  ---|
...                   |---> Trash
...                ---|
50 45 00 00 01 0C  ---|  # 50 45 00 00 PE Flag
00 2C 1B 81 19 CC     |---> File Header (PE Header)
01 00 2C 22 09 54  ---|  
01 2D 0E 00 00 7F  ---|
...                   |---> Optional Header
1E 2C 01 90 2D 99  ---|
2E 74 65 78 74 00  ---|  <--- Where we should go
00 12 2C 76 01 00     |     
...                   |---> Section Table
...                ---|
00 00 00 00 00 00  ---|
...                   |  File Alignment
00 00 00 00 00 00  ---|
```

Therefore, the equation is `start addr[Section Table] = File Start Address + PE offset(e_lfanew) + PE Flag(4 bytes) + size of PE Header(20 bytes) + size of Optional Header(SizeOfOptionalHeader)`, where `File Start Address` is 0.

## Parser for Section Table

Now let's write code in C language to parse section table.

```c
// Program: PE Parser
// This program is going to read PE file from disk to file buffer
// in virtual memory, and then parses fields of the PE file.
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define BYTE unsigned char
#define WORD unsigned short
#define DWORD unsigned int
#define PIMAGE_HEADER unsigned char*
#define nullptr NULL
#define DEBUG 0
#define IMAGE_SIZEOF_SHORT_NAME 8

typedef struct imageElement {
	size_t offset;
	size_t length;
	BYTE* val;
	DWORD dword;
} ImageElement;

struct {
	ImageElement e_magic;
	ImageElement e_lfanew;
} DOSHeader; 

struct {
	ImageElement Machine;
	ImageElement NumberOfSections;
	ImageElement TimeDateStamp;
	ImageElement PointerToSymbolTable;
	ImageElement NumberOfSymbols;
	ImageElement SizeOfOptionalHeader;
	ImageElement Characteristics;
} FileHeader; 

struct {
	ImageElement Magic;
	ImageElement SizeOfCode;
	ImageElement AddressOfEntryPoint;
	ImageElement ImageBase;
	ImageElement SectionAlignment;
	ImageElement FileAlignment;
	ImageElement SizeOfImage;
	ImageElement SizeOfHeaders;
	ImageElement CheckSum;
	ImageElement SizeOfStackReserve;
	ImageElement SizeOfStackCommit;
	ImageElement SizeOfHeapReserve;
	ImageElement SizeOfHeapCommit;
	ImageElement NumberOfRvaAndSizes;
} OptionalHeader;

typedef struct image_section_header {
	ImageElement Name;
	union {
		ImageElement PhysicalAddress;
		ImageElement VirtualSize;
	} Misc;
	ImageElement VirtualAddress;
	ImageElement SizeOfRawData;
	ImageElement PointerToRawData;
	ImageElement PointerToRelocations;
	ImageElement PointerToLinenumbers;
	ImageElement NumberOfRelocations;
	ImageElement NumberOfLinenumbers;
	ImageElement Characteristics;
} IMAGE_SECTION_HEADER;
IMAGE_SECTION_HEADER* p_section_header = nullptr;

// base of file buffer
PIMAGE_HEADER fileBase = nullptr;
// used as pointer for offset
PIMAGE_HEADER ptrAddr = nullptr;
// base of image buffer, simulate imageBase in system
PIMAGE_HEADER imageBase = nullptr;

void initImageElement(ImageElement* pEle, size_t offset, size_t length) {
	BYTE* buffer = nullptr;

	pEle->offset = offset;
	pEle->length = length;
	
	// read as pointer
	buffer = (BYTE*)malloc(sizeof(BYTE) * sizeof(DWORD));
	memset(buffer, 0, sizeof(BYTE) * sizeof(DWORD));
	memcpy(buffer, ptrAddr + pEle->offset, pEle->length);
	
	pEle->val = buffer;
	
	// read as DWORD
	memcpy(&pEle->dword, buffer, sizeof(BYTE) * sizeof(DWORD));
	
	buffer = nullptr;
}

void printElement(char* prompt, ImageElement* pEle) {
	size_t i;
	printf(prompt);
	
	for (i = 0; i < pEle->length; i++) {
		printf("%02x ", pEle->val[i]);
	}
	printf("\n");
	
	if (DEBUG) {
		printf("%04x\n", pEle->dword);
	}
}

// read file into file buffer and return the base address of file buffer
void readPEFile(BYTE* filename) {
	FILE *stream;
	size_t filesize = 0;
	size_t i;
	BYTE* fileBuffer = nullptr;
	int ch;
	
	if ((stream = fopen(filename, "rb")) != NULL) {
		// get file size
		fseek(stream, 0L, SEEK_END);
		filesize = ftell(stream);
		// reset stream pointer
		fseek(stream, 0L, SEEK_SET);

		// memory allocation and initialization
		fileBuffer = (BYTE*)malloc(sizeof(BYTE) * filesize + 1);
		if (fileBuffer == nullptr) {
			printf("Memory allocate failed.\n");
			fclose(stream);
			exit(-1);
		}

		memset(fileBuffer, 0, sizeof(BYTE) * filesize);

		// read stream to file
		ch = fgetc(stream);
		for (i = 0; i < filesize; i++) {
			fileBuffer[i] = (BYTE)ch;
			ch = fgetc(stream);
		}
		
		fileBase = fileBuffer;
		ptrAddr = fileBase;
		fclose(stream);
		
		if (DEBUG) {
			printf("Filesize: %d\n", filesize);
			printf("Buffersize: %d\n", i);
			printf("ptrAddr: %x\n", ptrAddr);
			printf("\n");
		}
	}
	else {
		printf("ERROR: The file was not opened properly.\n");
		exit(-1);
	}
}

void InitializeParserTable() {
	size_t number_of_sections = 0;
	size_t file_header_offset = 0;
	size_t size_of_a_section = 0x28;
	size_t i;

	// DOS Header
	initImageElement(&DOSHeader.e_magic, 0, 2);
	initImageElement(&DOSHeader.e_lfanew, 60, 4);
	
	// offset of PE Flag to DOS Header
	// sizeof PE flag is 4 bytes, which is '50 45 00 00'
	file_header_offset = DOSHeader.e_lfanew.dword + 4 - 1;
	ptrAddr += file_header_offset;

	// PE STD Header
	initImageElement(&FileHeader.Machine, 0, 2);
	initImageElement(&FileHeader.NumberOfSections, 2, 2);
	initImageElement(&FileHeader.TimeDateStamp, 4, 4);
	initImageElement(&FileHeader.PointerToSymbolTable, 8, 4);
	initImageElement(&FileHeader.NumberOfSymbols, 12, 4);
	initImageElement(&FileHeader.SizeOfOptionalHeader, 16, 2);
	initImageElement(&FileHeader.Characteristics, 18, 2);

	// change ptrAddr to Optional Header, the size of File Header is 20 bytes
	ptrAddr += 20;

	// PE Optional Header
	initImageElement(&OptionalHeader.Magic, 0, 2);
	initImageElement(&OptionalHeader.SizeOfCode, 4, 4);
	initImageElement(&OptionalHeader.AddressOfEntryPoint, 16, 4);
	initImageElement(&OptionalHeader.ImageBase, 28, 4);
	initImageElement(&OptionalHeader.SectionAlignment, 32, 4);
	initImageElement(&OptionalHeader.FileAlignment, 36, 4);
	initImageElement(&OptionalHeader.SizeOfImage, 56, 4);
	initImageElement(&OptionalHeader.SizeOfHeaders, 60, 4);
	initImageElement(&OptionalHeader.CheckSum, 64, 4);
	initImageElement(&OptionalHeader.SizeOfStackReserve, 72, 4);
	initImageElement(&OptionalHeader.SizeOfStackCommit, 76, 4);
	initImageElement(&OptionalHeader.SizeOfHeapReserve, 80, 4);
	initImageElement(&OptionalHeader.SizeOfHeapCommit, 84, 4);
	initImageElement(&OptionalHeader.NumberOfRvaAndSizes, 92, 4);
	// _IMAGE_DATA_DIRECTORY DataDirectory[16];

	// change ptrAddr to Section Table, the size of PE Optional Header is SizeOfOptionalHeader in File Header
	ptrAddr += FileHeader.SizeOfOptionalHeader.dword;

	if (DEBUG) {
		printf("value of ptrAddr is %x\n", (char)*ptrAddr);
	}

	// Initialization
	number_of_sections = FileHeader.NumberOfSections.dword;
	p_section_header = (IMAGE_SECTION_HEADER*)malloc(sizeof(IMAGE_SECTION_HEADER) * number_of_sections);
	memset(p_section_header, 0, sizeof(IMAGE_SECTION_HEADER) * number_of_sections);

	// Section Table
	for (i = 0; i < number_of_sections; i++) {
		initImageElement(&p_section_header[i].Name, 0, 8);
		initImageElement(&p_section_header[i].Misc.VirtualSize, 8, 4);
		initImageElement(&p_section_header[i].VirtualAddress, 12, 4);
		initImageElement(&p_section_header[i].SizeOfRawData, 16, 4);
		initImageElement(&p_section_header[i].PointerToRawData, 20, 4);
		initImageElement(&p_section_header[i].Characteristics, 36, 4);
		
		// go to table of next section
		ptrAddr += size_of_a_section;
	}
}

void printHeaders() {
	size_t i;
	char name[9] = {0};

	printf("======DOS HEADER======\n");
	printElement("e_magic: ", &DOSHeader.e_magic);
	printElement("e_lfanew: ", &DOSHeader.e_lfanew);
	printf("\n");

	printf("======File HEADER======\n");
	printElement("Machine: ", &FileHeader.Machine);
	printElement("NumberOfSections: ", &FileHeader.NumberOfSections);
	printElement("TimeDateStamp: ", &FileHeader.TimeDateStamp);
	printElement("PointerToSymbolTable: ", &FileHeader.PointerToSymbolTable);
	printElement("NumberOfSymbols: ", &FileHeader.NumberOfSymbols);
	printElement("SizeOfOptionalHeader: ", &FileHeader.SizeOfOptionalHeader);
	printElement("Characteristics: ", &FileHeader.Characteristics);
	printf("\n");

	printf("======Optional HEADER======\n");
	printElement("Magic: ", &OptionalHeader.Magic);
	printElement("SizeOfCode: ", &OptionalHeader.SizeOfCode);
	printElement("AddressOfEntryPoint: ", &OptionalHeader.AddressOfEntryPoint);
	printElement("ImageBase: ", &OptionalHeader.ImageBase);
	printElement("SectionAlignment: ", &OptionalHeader.SectionAlignment);
	printElement("FileAlignment: ", &OptionalHeader.FileAlignment);
	printElement("SizeOfImage: ", &OptionalHeader.SizeOfImage);
	printElement("SizeOfHeaders: ", &OptionalHeader.SizeOfHeaders);
	printElement("CheckSum: ", &OptionalHeader.CheckSum);
	printElement("SizeOfStackReserve: ", &OptionalHeader.SizeOfStackReserve);
	printElement("SizeOfStackCommit: ", &OptionalHeader.SizeOfStackCommit);
	printElement("SizeOfHeapReserve: ", &OptionalHeader.SizeOfHeapReserve);
	printElement("SizeOfHeapCommit: ", &OptionalHeader.SizeOfHeapCommit);
	printElement("NumberOfRvaAndSizes: ", &OptionalHeader.NumberOfRvaAndSizes);

	printf("======SECTION HEADER======\n");
	for (i = 0; i < FileHeader.NumberOfSections.dword; i++) {
		printf("Description of SECTION %d:\n", i);
		// a secure way to output name
		memcpy(name, p_section_header[i].Name.val, 8);
		name[8] = '\0';
		printf("Name: %s\n", name);
		printElement("Misc: ", &p_section_header[i].Misc.VirtualSize);
		printElement("VirtualAddress: ", &p_section_header[i].VirtualAddress);
		printElement("SizeOfRawData: ", &p_section_header[i].SizeOfRawData);
		printElement("PointerToRawData: ", &p_section_header[i].PointerToRawData);
		printElement("Characteristics: ", &p_section_header[i].Characteristics);
	}
}

void PEParser() {
	InitializeParserTable();
	printHeaders();
}

int main(int argc, char* argv[]) {
	readPEFile("notepad.exe");
    PEParser();

    return 0;
}
```

<EndMarkdown>