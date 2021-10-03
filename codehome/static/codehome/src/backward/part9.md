# PE Seg.1

## Table of Contents
- [5045 PE](#5045pe)
	- [Intuition](#intuition)
	- [Stretch](#stretch)
- [General Concepts](#generalconcepts)
- [File Headers](#fileheaders)
	- [DOS Header](#dosheader)
	- [PE STD Header](#pestdheader)
	- [Optional Header](#optionalheader)
	- [PE Parser](#peparser)

<TableEndMark>

## 5045 PE

What is PE? The Portable Executable (PE) format is a file format for executables, object code, DLLs and others used in 32-bit and 64-bit versions of Windows operating systems. The PE format is a data structure that encapsulates the information necessary for the Windows OS loader to manage the wrapped executable code. This includes dynamic library references for linking, API export and import tables, resource management data and thread-local storage (TLS) data. On NT operating systems, the PE format is used for EXE, DLL, SYS (device driver), and other file types. The Extensible Firmware Interface (EFI) specification states that PE is the standard executable format in EFI environments. 

BTW `0x50 0x45` is annotated as `PE` in ASCII, therefore PE gets its name from there more or less.

### Intuition

Before we explore PE, let's compare two binary files -- builtin .exe file `notepad` in hard disk and in memory.

![notepad in hard disk](codehome/src/img/backward/notepad-hard.png)

![notepad in memory](codehome/src/img/backward/notepad-memory.png)

Two differences are easy to find,

- file size: of hard disk is smaller than that of memory although the code of these two files are same.
- address: the address starts at 0 in hard disk, but at `00100000` in memory.

### Stretch

Why does file in memory is larger? There are two reasons for it.

1. Save Storage of Hard Disk: for history reason, hard disk in the past was small, and thereby scientists had to use it carefully.
2. Memory Alignment to Improve Access Speed: the idea here is similar to word alignment.

```bash
#  hard disk alignment, padding 0
     _____________       _  
    |  section1   |       |--> 200h bytes
    |_________0000|      _|
    |  section2   |
    |_______000000|
    |  section3   |
    |___________00|
    |             |

#  memory alignment, padding 0
     _____________       _  
    |  0x28       |       |
    |      0x96   |       |--> 1000h bytes
    |____000000000|      _|
    |             |
    |  0xf1       |
    |__________000|
    |             |
    |  section3   |
    |_______000000|
    |             |
```

## General Concepts

Certain concepts that appear throughout notebooks are described in the following table:

| Name | Description |
| :---: | :---: |
| attribute certificate | A certificate that is used to associate verifiable statements with an image. A number of different verifiable statements can be associated with a file; one of the most useful ones is a statement by a software manufacturer that indicates what the message digest of the image is expected to be. A message digest is similar to a checksum except that it is extremely difficult to forge. Therefore, it is very difficult to modify a file to have the same message digest as the original file. |
| date/time stamp | A stamp that is used for different purposes in several places in a PE or COFF file. In most cases, the format of each stamp is the same as that used by the time functions in the C run-time library. |
| file pointer | The location of an item within the file itself, before being processed by the linker (in the case of object files) or the loader (in the case of image files). In other words, this is a position within the file as stored on disk. |
| linker | A reference to the linker that is provided with Microsoft Visual Studio. |
| object file | A file that is given as input to the linker. The linker produces an image file, which in turn is used as input by the loader. The term "object file" does not necessarily imply any connection to object-oriented programming. |
| reserved, must be 0 | A description of a field that indicates that the value of the field must be zero for generators and consumers must ignore the field. |
| Relative virtual address (RVA) | In an image file, this is the address of an item after it is loaded into memory, with the base address of the image file subtracted from it. The RVA of an item almost always differs from its position within the file on disk (file pointer). In an object file, an RVA is less meaningful because memory locations are not assigned. In this case, an RVA would be an address within a section (described later in this table), to which a relocation is later applied during linking. For simplicity, a compiler should just set the first RVA in each section to zero. |
| section | The basic unit of code or data within a PE or COFF file. For example, all code in an object file can be combined within a single section or (depending on compiler behavior) each function can occupy its own section. With more sections, there is more file overhead, but the linker is able to link in code more selectively. A section is similar to a segment in Intel 8086 architecture. All the raw data in a section must be loaded contiguously. |
| Virtual Address (VA) | Same as RVA, except that the base address of the image file is not subtracted. The address is called a VA because *Windows creates a distinct VA space for each process*, independent of physical memory. For almost all purposes, a VA should be considered just an address. A VA is not as predictable as an RVA because the loader might not load the image at its preferred location. |

BTW, in 32-bit system, virtual memory takes 4G (0x00000000~0xFFFFFFFF).

```bash
# layout of PE
     ______________  _____    
    |  DOS Header  |     |
    |______________|     |
    |  NT Headers  |---| |
    |______________|   | |
    |  File Header |<--| |  # <-- or std PE header 
    |______________|   | |
    |   Optional   |   | |--> SizeOfHeaders
    |    Header    |<--| |
    |______________|     | 
    |   Table of   |     |
    |   Sections   | ____|
    |     ....     |
    |______________|
    |   Section1   |
    |    (.text)   |
    |______________|
    |   Section2   |
    |    (data)    |
    |______________|
    |   Section3   |
    |  (resources) |
    |______________|
    |              |
    |     ....     |
    |______________|
    |              |
    |   Section N  |
    |______________|
```

## File Headers

### DOS Header

| Offset | Size | Field | Description |
| :---: | :---: | :---: | :----: |
| 0 | 2 | e_magic | used for judge if an executable file |
| 2 | 4 | e_cblp | reserved, zero by default (IGNORE) |
| ... | ... | ... | ... |
| 60 | 4 | e_lfanew | offset of PE flag to the origin of file |

Notice that `e_lfanew` points to `0x50 0x45 0x00 0x00` which takes 4 bytes, after which the standard PE Header begins.

### PE STD Header

At the beginning of an object file, or immediately after the signature of an image file, is a standard PE file header in the following format. Note that the Windows loader limits the number of sections to 96.

| Offset | Size | Field | Description |
| :---: | :---: | :---: | :----: |
| 0 | 2 | Machine | The number that identifies the type of target machine. |
| 2 | 2 | NumberOfSections | The number of sections. This indicates the size of the section table, which immediately follows the headers. |
| 4 | 4 | TimeDateStamp | The low 32 bits of the number of seconds since 00:00 January 1, 1970 (a C run-time time_t value), which indicates when the file was created. |
| 8 | 4 | PointerToSymbolTable | The file offset of the COFF symbol table, or zero if no COFF symbol table is present. This value should be zero for an image because COFF debugging information is deprecated. (IGNORE)|
| 12 | 4 | NumberOfSymbols | The number of entries in the symbol table. This data can be used to locate the string table, which immediately follows the symbol table. (IGNORE) |
| 16 | 2 | SizeOfOptionalHeader | The size of the optional header, which is required for executable files but not for object files. This value should be zero for an object file. | 
| 18 | 2 | Characteristics | The flags that indicate the attributes of the file. |

- Machine: as showing above, machine identifies the type of target machine. `0x0` for any machine type, `0x01c0` for ARM little endian machine, and `0x014c` for Intel 386 or later processors and compatible processors.
- TimeDateStamp: for notepad in hard disk, the time date stamp is `0x41107cc3`, which is 34 years. hence the time when the file was created is `2004 = 1970 + 34`.
- SizeOfOptionalHeader: the size of optional header is various. By default the size is e0h in x86 machine, while f0h in x86_64 machine.


### Optional Header

Every image file has an optional header that provides information to the loader. This header is optional in the sense that some files (specifically, object files) do not have it. For image files, this header is required. An object file can have an optional header, but generally this header has no function in an object file except to increase its size.

Note that the size of the optional header is not fixed.

| Offset | Size | Field | Description |
| :---: | :---: | :---: | :----: |
| 0 | 2 | Magic | The unsigned integer that identifies the state of the image file. The most common number is 0x10B, which identifies it as a normal executable file. 0x107 identifies it as a ROM image, and 0x20B identifies it as a PE32+ executable. |
| 2 | 1 | MajorLinkerVersion | The linker major version number. (IGNORE) | 
| 3 | 1 | MinorLinkerVersion | The linker minor version number. (IGNORE) |
| 4 | 4 | SizeOfCode | The size of the code (text) section, or the sum of all code sections if there are multiple sections. (IGNORE) | 
| 8 | 4 | SizeOfInitializedData | The size of the initialized data section, or the sum of all such sections if there are multiple data sections. (IGNORE) |
| 12 | 4 | SizeOfUninitializedData |The size of the uninitialized data section (BSS), or the sum of all such sections if there are multiple BSS sections. (IGNORE) |
| 16 | 4 | AddressOfEntryPoint | The address of the entry point **relative to the image base** when the executable file is loaded into memory. For program images, this is the starting address. For device drivers, this is the address of the initialization function. An entry point is optional for DLLs. When no entry point is present, this field must be zero. |
| 20 | 4 | BaseOfCode | The address that is relative to the image base of the beginning-of-code section when it is loaded into memory. (IGNORE) |

PE32 contains this additional field, which is absent in PE32+, following BaseOfCode.

| Offset | Size | Field | Description |
| :---: | :---: | :---: | :----: |
| 24 | 4 | BaseOfData | The address that is relative to the image base of the beginning-of-data section when it is loaded into memory. (IGNORE) |

The next 21 fields are an extension to the COFF optional header format. They contain additional information that is required by the linker and loader in Windows.

| Offset | Size | Field | Description |
| :---: | :---: | :---: | :----: |
| 28 | 4 | ImageBase | The preferred address of the first byte of image when loaded into memory; must be a multiple of 64 K. The default for DLLs is 0x10000000. The default for Windows CE EXEs is 0x00010000. The default for Windows NT, Windows 2000, Windows XP, Windows 95, Windows 98, and Windows Me is 0x00400000. |
| 32 | 4 | SectionAlignment | The alignment (in bytes) of sections when they are loaded into memory. It must be greater than or equal to FileAlignment. The default is the page size for the architecture. |
| 36 | 4 | FileAlignment | The alignment factor (in bytes) that is used to align the raw data of sections in the image file. The value should be a power of 2 between 512 and 64 K, inclusive. The default is 512. |
| 40 | 2 | MajorOperatingSystemVersion | The major version number of the required operating system. (IGNORE) |
| 42 | 2 | MinorOperatingSystemVersion | The minor version number of the required operating system. (IGNORE) | 
| 44 | 2 | MajorImageVersion | The major version number of the image. (IGNORE) |
| 46 | 2 | MinorImageVersion | The minor version number of the image. (IGNORE) |
| 48 | 2 | MajorSubsystemVersion | The major version number of the subsystem. (IGNORE) |
| 50 | 2 | MinorSubsystemVersion | The minor version number of the subsystem. (IGNORE) |
| 52 | 4 | Win32VersionValue | Reserved, must be zero. (IGNORE) |
| 56 | 4 | SizeOfImage | The size (in bytes) of the image, including all headers, as the image is loaded in memory. **It must be a multiple of SectionAlignment**. |
| 60 | 4 | SizeOfHeaders | The combined size of an MS-DOS stub, PE header, and section headers **rounded up to a multiple of FileAlignment**. |
| 64 | 4 | CheckSum | The image file checksum. The algorithm for computing the checksum is incorporated into IMAGHELP.DLL. |
| 68 | 2 | Subsystem | The subsystem that is required to run this image. (IGNORE) |
| 70 | 2 | DllCharacteristics | For more information, see DLL Characteristics later. (IGNORE) |
| 72 | 4 | SizeOfStackReserve | The size of the stack to reserve. Only SizeOfStackCommit is committed; the rest is made available one page at a time until the reserve size is reached. |
| 76 | 4 | SizeOfStackCommit | The size of the stack to commit. |
| 80 | 4 | SizeOfHeapReserve | The size of the local heap space to reserve. Only SizeOfHeapCommit is committed; the rest is made available one page at a time until the reserve size is reached. |
| 84 | 4 | SizeOfHeapCommit | The size of the local heap space to commit. |
| 88 | 4 | LoaderFlags | Reserved, must be zero. (IGNORE) |
| 92 | 4 | NumberOfRvaAndSizes | The number of data-directory entries in the remainder of the optional header. Each describes a location and size. | 

- SizeOfCode: must be the multiple of FileAlignment.
- SizeOfInitializedData: must be the multiple of FileAlignment.
- SizeOfUninitializedData: must be the multiple of FileAlignment.
- SectionAlignment: for old version machine, 200h, and for new machine, 1000h, which is same as FileAlignment
- FileAlignment: 1000h by default.
- AddressOfEntryPoint: The address of entry point in memory (`ImageBase + AddressOfEntryPoint`) has nothing to do with the beginning of program. In general, the beginning of program is in the address of entry point, which is in the code (`.text`) section.

##### Physical Memory and Virtual Memory

The OS will allocate a virtual memory for each process(or running program), which has 4G memory. It is virtual address(VA) that indexes this virtual memory. It can be summarized as `virtual address = relative virtual address + image base`. 

Yet the actual address of physical memory is allocated by process loader, which will assign memory according to which physical memory blocks are used or available. In general, it will shift VA linearly in physical memory.

```bash
#  hard disk alignment, padding 0
     _____________       _     <-- RVA 0x00000000
    |  section1   |       |--> 200h bytes
    |_________0000|      _|
    |  section2   |
    |_______000000|
    |  section3   |
    |___________00|
    |             |
         
      File Buffer


#  after stretching in virtual memory, memory alignment, padding 0
     _____________   _   _     <-- VA 0x00400000
    |  0x28       |   |   |
    |      0x96   |   |   |--> 1000h bytes
    |____000000000|   |  _|
    |             |   |
    |  0xf1       |   |---> SizeOfImage
    |__________000|   |
    |             |   |
    |  section3   |   |
    |_______000000|   |
    |             |  _|

      Image Buffer

#  physical memory, shift linearly + 0x00200000 for example
     _____________       _     <-- VA 0x00600000
    |  0x28       |       |
    |      0x96   |       |--> 1000h bytes
    |____000000000|      _|
    |             |
    |  0xf1       |
    |__________000|
    |             |
    |  section3   |
    |_______000000|
    |             |
```

### PE Parser

Now let's write a parser to help us parse fields of PE instead of doing it manually.

```c
// PELoader.h
#include <stdio.h>
#include <stdlib.h>
#define nullptr NULL
#define BYTE unsigned char
void readPEFile(BYTE* filename);

// PEReader.c
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
		fileBuffer = (BYTE*)malloc(sizeof(BYTE) * filesize);
		if (fileBuffer == nullptr) {
			printf("Memory allocate failed.\n");
			fclose(stream);
			exit(-1);
		}
		memset(fileBuffer, 0, sizeof(BYTE) * filesize);

		// read stream to file buffer
		ch = fgetc(stream);
		for (i = 0; i < filesize; i++) {
			fileBuffer[i] = (BYTE)ch;
			ch = fgetc(stream);
		}

		// or use 'fread'
		// n = fread(fileBuffer, sizeof(char), filesize, stream);
		// if (!n) {
		//	   printf("Failed to read file.\n");
		//     free(fileBuffer);
		//     fclose(stream);
		//     exit(-1);
		// }
		
		baseAddr = fileBuffer;
		fclose(stream);
		
		if (DEBUG) {
			printf("Filesize: %d\n", filesize);
			printf("Buffersize: %d\n", i);
			printf("BaseAddr: %x\n", baseAddr);
			printf("\n");
		}
	}
	else {
		printf("ERROR: The file was not opened properly.\n");
		exit(-1);
	}
}
```

```c
// Program: PE Parser
// This program is going to read PE file from disk to file buffer
// in virtual memory, and then parses fields of the PE file.
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "PEReader.h"

#define BYTE unsigned char
#define WORD unsigned short
#define DWORD unsigned int
#define size_t unsigned int
#define PIMAGE_HEADER unsigned char*
#define nullptr NULL
#define DEBUG 0

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

PIMAGE_HEADER baseAddr = nullptr;

void initImageElement(ImageElement* pEle, size_t offset, size_t length) {
	BYTE* buffer = nullptr;

	pEle->offset = offset;
	pEle->length = length;
	
	// read as pointer
	buffer = (BYTE*)malloc(sizeof(BYTE) * sizeof(DWORD));
	memset(buffer, 0, sizeof(BYTE) * sizeof(DWORD));
	memcpy(buffer, baseAddr + pEle->offset, pEle->length);
	
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

void InitializeParserTable() {
	size_t file_header_offset = 0;

	// DOS Header
	initImageElement(&DOSHeader.e_magic, 0, 2);
	initImageElement(&DOSHeader.e_lfanew, 60, 4);
	
	// offset of PE Flag to DOS Header
	// sizeof PE flag is 4 bytes, which is '50 45 00 00'
	file_header_offset = DOSHeader.e_lfanew.dword + 4;
	baseAddr += file_header_offset;

	// PE STD Header
	initImageElement(&FileHeader.Machine, 0, 2);
	initImageElement(&FileHeader.NumberOfSections, 2, 2);
	initImageElement(&FileHeader.TimeDateStamp, 4, 4);
	initImageElement(&FileHeader.PointerToSymbolTable, 8, 4);
	initImageElement(&FileHeader.NumberOfSymbols, 12, 4);
	initImageElement(&FileHeader.SizeOfOptionalHeader, 16, 2);
	initImageElement(&FileHeader.Characteristics, 18, 2);

	// change baseAddr to Optional Header, the size of File Header is 20 bytes
	baseAddr += 20;

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

}

void printHeaders() {
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

Compared with notepad opened by DTDebug, the code in file buffer will prove something we discussed above.

![Output Comparison](codehome/src/img/backward/output.png)

<EndMarkdown>