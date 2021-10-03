# Coding

## Table of Contents
- [Philosophy of Coding](#philosophyofcoding)
- [PE Operation](#peoperation)
	- [Structure](#structure)
	- [Global](#global)
	- [PEReader](#pereader)
	- [PEParser](#peparser)
	- [Tools](#tools)

<TableEndMark>

## Philosophy of Coding

There are most valuable principles in software development: **Cohesion** represents the degree to which a part of a code base forms a logically single, atomic unit. **Coupling**, on the other hand, represents the degree to which a single unit is independent from others. In other words, it is the number of connections between two or more units. The fewer the number, the lower the coupling.

From perspective of cohesion and coupling, there are four types of programming.

![Cohesion-Coupling Coordinate](codehome/src/img/backward/coordinate-cohesion-coupling.png)

However, high cohesion and low coupling is the best way to organize our project, which gives us better designed code that is easier to maintain.

- High Cohesion: means keeping parts of a code base that are related to each other in a single place. 
- Low Coupling: is about separating unrelated parts of the code base as much as possible.

![loosely coupled and highly cohesive](codehome/src/img/backward/IdealDiagram.png)

Following this guide, we will reorganize our previous codes.

## PE Operation

### Structure 

The structure of our project is as follows,

```bash
# PE Operation Structure
Global.h --|-------->--------|
           |                 |
           |--> PEReader.h --|--> Tools.h
           |                 |
           |--> PEParser.h --|
# Global.h: contains definition globally, macro definition and type definition.
# PEReader: reads a sequence of data from a file into memory.
# PEParser: parse members of headers of a given PE buffer.
# Tools: contains a lot of functions used to operate on PE buffer.
```

### Global

```c
// Global.h:
//     contains variable, macro and type definition which is used globally
 
#ifndef GLOBAL_H
#define GLOBAL_H
#pragma once

#include <stdio.h>

// Extension from C++
#define nullptr NULL
#define DEBUG 0

// Descriptor, no practical meaning
#define IN
#define OUT

// Unit
#define BYTE unsigned char
#define WORD unsigned short
#define DWORD unsigned int
#define STATUS unsigned int
#define PFILEBASE unsigned char*
#define PMEMORYBASE unsigned char*

#define SIZEOF_SECTION_NAME 8
#define IMAGE_NT_SIGNATURE 0X00004550
#define IMAGE_SIZEOF_FILE_HEADER 20

// Base Address
PMEMORYBASE fileBuffer;
PMEMORYBASE imageBuffer;

// Headers
typedef struct dosHeader {
	WORD e_magic;
	BYTE offset[58];  // offset is used to ignore useless members
	DWORD e_lfanew;
} DOSHeader;
DOSHeader* pDosHeader;

typedef struct fileHeader {
	WORD Machine;
	WORD NumberOfSections;
	DWORD TimeDateStamp;
	DWORD PointerToSymbolTable;
	DWORD NumberOfSymbols;
	WORD SizeOfOptionalHeader;
	WORD Characteristics;
} FILEHeader;
FILEHeader* pFileHeader;

typedef struct optionalHeader {
	WORD Magic;
	DWORD SizeOfCode;
	BYTE offseta[8];
	DWORD AddressOfEntryPoint;
	BYTE offsetb[8];
	DWORD ImageBase;
	DWORD SectionAlignment;
	DWORD FileAlignment;
	BYTE offsetc[16];
	DWORD SizeOfImage;
	DWORD SizeOfHeaders;
	DWORD CheckSum;
	BYTE offsetd[4];
	DWORD SizeOfStackReserve;
	DWORD SizeOfStackCommit;
	DWORD SizeOfHeapReserve;
	DWORD SizeOfHeapCommit;
	BYTE offsete[4];
	DWORD NumberOfRvaAndSizes;
	// _IMAGE_DATA_DIRECTORY DataDirectory[16];
} OPTIONALHeader;
OPTIONALHeader* pOptionalHeader;

typedef struct image_section_header {
	char Name[SIZEOF_SECTION_NAME];
	union {
		DWORD PhysicalAddress;
		DWORD VirtualSize;
	} Misc;
	DWORD VirtualAddress;
	DWORD SizeOfRawData;
	DWORD PointerToRawData;
	BYTE offset[12];
	DWORD Characteristics;
} IMAGE_SECTION_HEADER;
IMAGE_SECTION_HEADER* p_section_header;

// Auxiliary tools

// printInMemoryFormat:
//     This function will print memory data in memory format, that is little-endian.
// @addr: address of memory data.
// @size: the size of memory data that will be displayed. 
STATUS printInMemoryFormat(IN BYTE* addr, IN size_t size);

#endif
```

```c
// Global.c
#include "Global.h"

STATUS printInMemoryFormat(IN BYTE* addr, IN size_t size) {
	size_t i = 0;
	for (; i < size; i++) {
		printf("%02x ", addr[i]);
	}
	printf("\n");

	return 0;
}
```

### PEReader

```c
// PEReader.h:
//     This program will read a file into memory, which is termed file buffer,
// and return the status code of function, success or failure.

#ifndef PEREADER_H
#define PEREADER_H
#pragma once

#include "Global.h"
#include <stdio.h>
#include <stdlib.h> // for 'malloc'
#include <string.h> // for 'memset'

// PEReader:
//     read a file into memory in binary code, return status value.
// @filename: the name or path/name of input file
// @baseOfFileBuffer: an address of a pointer to file buffer
STATUS PEReader(IN char* filename, OUT PFILEBASE* baseOfFileBuffer);

#endif
```

```c
#include "PEReader.h"

STATUS PEReader(IN char* filename, OUT PFILEBASE* baseOfFileBuffer) {
	FILE *stream;
	size_t filesize = 0;
	int flag = 0;
	BYTE* fileBuffer = nullptr;
	
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
			return 255;
		}

		memset(fileBuffer, 0, sizeof(BYTE) * filesize);

		// memory read
		flag = fread(fileBuffer, sizeof(BYTE), filesize, stream);
		if (!flag) {
		    printf("Failed to read file.\n");
		    free(fileBuffer);
		    fclose(stream);
		    return 254;
		}
		
		fclose(stream);
		
		if (DEBUG) {
			printf("PEReader.PEReader:\n");
			printf("Filesize: %d\n", filesize);
			printf("fileBufferAddr: %x\n", fileBuffer);
			printf("\n");
		}
		
		*baseOfFileBuffer = fileBuffer;

		return 0;
	}
	else {
		printf("ERROR: The file was not opened properly.\n");
		return 253;
	}
}
```

### PEParser

Notice that in new version of `Global.h`, we change the struct of PE Headers unlike before we did. In the past, we predefined a type termed `ImageElement` to record each element to represents how to use union in C. Now we directly use struct pointer to do the job it did.

*BTW, the essence of pointer is an address, and it is provided for programmer to tell system how to use or explain memory data.*

```c
// PEParser.h:
#ifndef PEPARSER_h
#define PEPARSER_h
#pragma once

#include "Global.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// PEParser:
//     The function will parse members of PE headers.
// @filebase: the base address of file buffer.
STATUS PEParser(IN PMEMORYBASE filebase);

// printHeaders:
//     printHeaders will print DosHeader, FileHeader, and OptionalHeader.
void printHeaders();

#endif
```

```c
// PEParser.c
#include "PEParser.h"

void printHeaders() {
	WORD i;
	char name[9];

	printf("======DOS HEADER======\n");
	printf("e_magic: %x\n", pDosHeader->e_magic);
	printf("e_lfanew: %x\n", pDosHeader->e_lfanew);

	if (DEBUG) {
		printf("PEParser.printHeaders:\n");
		printInMemoryFormat((BYTE*)&pDosHeader->e_magic, sizeof(pDosHeader->e_magic));
		printInMemoryFormat((BYTE*)&pDosHeader->e_lfanew, sizeof(pDosHeader->e_lfanew));
		printf("\n");
	}

	printf("\n");

	printf("======File HEADER======\n");
	printf("Machine: %x\n", pFileHeader->Machine);
	printf("NumberOfSections: %x\n", pFileHeader->NumberOfSections);
	printf("TimeDateStamp: %x\n", pFileHeader->TimeDateStamp);
	printf("PointerToSymbolTable: %x\n", pFileHeader->PointerToSymbolTable);
	printf("NumberOfSymbols: %x\n", pFileHeader->NumberOfSymbols);
	printf("SizeOfOptionalHeader: %x\n", pFileHeader->SizeOfOptionalHeader);
	printf("Characteristics: %x\n", pFileHeader->Characteristics);
	printf("\n");

	printf("======Optional HEADER======\n");
	printf("Magic: %x\n", pOptionalHeader->Magic);
	printf("SizeOfCode: %x\n", pOptionalHeader->SizeOfCode);
	printf("AddressOfEntryPoint: %x\n", pOptionalHeader->AddressOfEntryPoint);
	printf("ImageBase: %x\n", pOptionalHeader->ImageBase);
	printf("SectionAlignment: %x\n", pOptionalHeader->SectionAlignment);
	printf("FileAlignment: %x\n", pOptionalHeader->FileAlignment);
	printf("SizeOfImage: %x\n", pOptionalHeader->SizeOfImage);
	printf("SizeOfHeaders: %x\n", pOptionalHeader->SizeOfHeaders);
	printf("CheckSum: %x\n", pOptionalHeader->CheckSum);
	printf("SizeOfStackReserve: %x\n", pOptionalHeader->SizeOfStackReserve);
	printf("SizeOfStackCommit: %x\n", pOptionalHeader->SizeOfStackCommit);
	printf("SizeOfHeapReserve: %x\n", pOptionalHeader->SizeOfHeapReserve);
	printf("SizeOfHeapCommit: %x\n", pOptionalHeader->SizeOfHeapCommit);
	printf("NumberOfRvaAndSizes: %x\n", pOptionalHeader->NumberOfRvaAndSizes);
	printf("\n");

	printf("======SECTION HEADER======\n");
	for (i = 0; i < pFileHeader->NumberOfSections; i++) {
		printf("Description of SECTION %d:\n", i);
		// a secure way to print name
		memset(name, 0, sizeof(name));
		memcpy(name, p_section_header[i].Name, 8);
		name[8] = '\0';
		printf("Name: %s\n", name);
		printf("Misc: %x\n", p_section_header[i].Misc.VirtualSize);
		printf("VirtualAddress: %x\n", p_section_header[i].VirtualAddress);
		printf("SizeOfRawData: %x\n", p_section_header[i].SizeOfRawData);
		printf("PointerToRawData: %x\n", p_section_header[i].PointerToRawData);
		printf("Characteristics: %x\n", p_section_header[i].Characteristics);
		printf("\n");
	}
}

STATUS PEParser(IN PMEMORYBASE filebase) {
	DWORD* pNTHeader = nullptr;
	pDosHeader = (DOSHeader*)filebase;
	
	// Check PE Signature: 
	// Noting that it is a good behavior to add type conversion for pointer arithmetic operation
	pNTHeader = (DWORD*)((DWORD)filebase + pDosHeader->e_lfanew);

	if (*pNTHeader != IMAGE_NT_SIGNATURE) {
		printf("Check PE Signature failure: PE Signature is not found.\n");
		return 254;
	}
    
	// Update pointers to headers
	pFileHeader = (FILEHeader*)((DWORD)pNTHeader + 4);
	pOptionalHeader = (OPTIONALHeader*)((DWORD)pFileHeader + IMAGE_SIZEOF_FILE_HEADER);
	p_section_header = (IMAGE_SECTION_HEADER*)((DWORD)pOptionalHeader + pFileHeader->SizeOfOptionalHeader);

	// printHeaders();
	
	if (DEBUG) {
		printf("PEParser.PEParser:\n");
		printf("pDosHeader->e_lfanew: %x\n", pDosHeader->e_lfanew);
		printf("filebas: %x\n", (DWORD)filebase);
		printf("(DWORD)filebase + pDosHeader->e_lfanew = %x\n", (DWORD)filebase + pDosHeader->e_lfanew);
		printf("\n");
	}

	return 0;
}
```

### Tools

As you can see, in `Tools.h` we define some useful functions, which is highly cohesive and loosely coupling. Besides, there are some `TEST_` functions defined here to test the property of functions above.

```c
#ifndef TOOLS_H
#define TOOLS_H
#pragma once

#include "Global.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "PEParser.h"
#include "PEReader.h"

// VAToFOA:
//     The function will translate virtual address to file offset address of given file buffer.
// @virtualAddress: virtual address of data in image buffer.
// @fileBuffer: the base address of file buffer.
BYTE* VAToFOA(IN BYTE* virtualAddress, IN BYTE* fileBuffer);

// FileBufferToImageBuffer:
//     The function will stretch a file buffer to an image buffer.
// @fileBuffer: the base address of file buffer.
// @imageBuffer: the base address of image buffer.
STATUS FileBufferToImageBuffer(IN PMEMORYBASE fileBuffer, OUT PMEMORYBASE* imageBuffer);

// ImageBufferToFileBuffer:
//     The function will pack an image buffer as a file buffer
// @imageBuffer: the base address of image buffer.
// @fileBuffer: the base address of file buffer.
STATUS ImageBufferToFileBuffer(IN PMEMORYBASE imageBuffer, OUT PMEMORYBASE* fileBuffer);

// SaveBufferAsFile:
//     The function will save memory data in a file.
// @filename: the name of file to save, in general it is an empty file.
// @buffer: the base address of memory buffer.
// @filesize: the size of the file.
STATUS SaveBufferAsFile(IN char* filename, IN PMEMORYBASE buffer);


// Auxiliary Functions:

// calculateFileBufferSize:
//     This function will return the size of a file buffer.
// @fileBuffer: base address of file buffer.
// Noting: this function will change PE headers
DWORD calculateFileBufferSize(IN PMEMORYBASE fileBuffer);


// Test Functions:

// TEST_VAToFOA:
//     This function tests validation of the process of translating from virtual address to file offset address, 
// and returns the file offset address in given file buffer.
void TEST_VAToFOA();

// TEST_FileOperation:
//     This function tests following operations:
//     1. read data from file into a memory buffer.
//     2. parse headers.
//     3. transfer from file buffer to image buffer.
//     4. transfer from image buffer to file buffer.
//     5. save file buffer as a file.
void TEST_FileOperation();

#endif
```

```c
#include "Tools.h"

int isInSection(int rva, int sec_begin, int sec_end) {
	if (rva >= sec_begin && rva <= sec_end) {
		return 1;
	}

	return 0;
}

BYTE* VAToFOA(IN BYTE* virtualAddress, IN BYTE* fileBuffer) {
	size_t i = 0;
	DWORD section_num = -1;
	DWORD rva = (DWORD)virtualAddress - pOptionalHeader->ImageBase;
	BYTE* fileOffsetAddress = nullptr;
	size_t number_of_sections = (size_t)pFileHeader->NumberOfSections;
	DWORD offset = 0;

	// check which section it belongs to
	for (; i < number_of_sections; i++) {
		if (isInSection(rva, p_section_header[i].VirtualAddress, p_section_header[i].VirtualAddress + p_section_header[i].Misc.VirtualSize)) {
			section_num = i;
			break;
		}
	}

	// error checking
	if (section_num == -1) {
		printf("Error: Data is not in legal range of any section.\n");
		exit(-1);
	}

	// calculate offset to the begin of section in image buffer
	offset = rva - p_section_header[section_num].VirtualAddress;

	// get the address of file buffer
	fileOffsetAddress = (BYTE*)((DWORD)fileBuffer + p_section_header[section_num].PointerToRawData + offset);

	return fileOffsetAddress;
}

STATUS FileBufferToImageBuffer(IN PMEMORYBASE fileBuffer, OUT PMEMORYBASE* imageBuffer) {
	DWORD i;
	// memory allocation for image buffer
	PMEMORYBASE imgBuffer = (PMEMORYBASE)malloc(sizeof(BYTE) * pOptionalHeader->SizeOfImage);
	if (imgBuffer == nullptr) {
		printf("Memory allocation failed.\n");
		return 255;
	}
	memset(imgBuffer, 0, pOptionalHeader->SizeOfImage);

	// copy headers
	memcpy(imgBuffer, fileBuffer, pOptionalHeader->SizeOfHeaders);

	// copy sections
	for (i = 0; i < pFileHeader->NumberOfSections; i++) {
		memcpy(&imgBuffer[p_section_header[i].VirtualAddress], &fileBuffer[p_section_header[i].PointerToRawData], sizeof(BYTE) * p_section_header[i].SizeOfRawData);
	}
	
	if (DEBUG) {
		printf("Tools.FileBufferToImageBuffer:\n");
		printf("file buffer: %x\n", fileBuffer);
		printf("image buffer: %x\n", imgBuffer);
		printf("\n");
	}

	*imageBuffer = imgBuffer;
	imgBuffer = nullptr;

	return 0;
}



STATUS ImageBufferToFileBuffer(IN PMEMORYBASE imageBuffer, OUT PMEMORYBASE* rt_fileBuffer) {
	DWORD i;
	DWORD sizeOfFileBuffer = 0;
	PMEMORYBASE fileBuffer = nullptr; 
	
	// memory allocation for file buffer
	sizeOfFileBuffer = calculateFileBufferSize(imageBuffer);
	fileBuffer = (PMEMORYBASE)malloc(sizeof(BYTE) * sizeOfFileBuffer);
	if (fileBuffer == nullptr) {
		printf("Memory allocation failed.\n");
		return 255;
	}
	memset(fileBuffer, 0, sizeOfFileBuffer);

	// copy headers
	memcpy(fileBuffer, imageBuffer, pOptionalHeader->SizeOfHeaders);

	// copy sections
	for (i = 0; i < pFileHeader->NumberOfSections; i++) {
		memcpy(&fileBuffer[p_section_header[i].PointerToRawData], &imageBuffer[p_section_header[i].VirtualAddress], sizeof(BYTE) * p_section_header[i].SizeOfRawData);
	}

	*rt_fileBuffer = fileBuffer;
	fileBuffer = nullptr;

	if (DEBUG) {
		printf("Tools.ImageBufferToFileBuffer:\n");
		printf("image buffer: %x\n", imageBuffer);
		printf("file buffer: %x\n", *rt_fileBuffer);
		printf("\n");
	}

	return 0;
}

STATUS SaveBufferAsFile(IN char* filename, IN PMEMORYBASE buffer) {
	FILE *stream;
	int flag = 0;
	DWORD filesize = calculateFileBufferSize(buffer);
	
	if ((stream = fopen(filename, "wb")) != nullptr) {
		flag = fwrite(buffer, sizeof(BYTE), filesize, stream);

		if (!flag) {
			printf("Failed to write file.\n");
			fclose(stream);
			return 255;
		}

		fclose(stream);
		printf("Completed to save to a file.\n");

		return 0;
	}
	else {
		printf("Failed to open a new file.\n");
		return 254;
	}
}


DWORD calculateFileBufferSize(IN PMEMORYBASE fileBuffer) {
	DWORD i;
	DWORD sizeOfFileBuffer = 0;
	STATUS ret;
	
	// update headers
	ret = PEParser(fileBuffer);

	if (DEBUG) {
		printf("Tools.calculateFileBufferSize:\n");
		printf("DOSHeader: %x\n", pDosHeader);
		printf("FileHeader: %x\n", pFileHeader);
		printf("OptionalHeader: %x\n", pOptionalHeader);
		printf("\n");
	}

	sizeOfFileBuffer = pOptionalHeader->SizeOfHeaders;
	for (i = 0; i < pFileHeader->NumberOfSections; i++) {
		sizeOfFileBuffer += p_section_header[i].SizeOfRawData;
	}

	return sizeOfFileBuffer;
}


// Test Functions:

void TEST_VAToFOA() {
	STATUS ret;
	PMEMORYBASE fileBuffer = nullptr;
	PMEMORYBASE imgBuffer = nullptr;
	BYTE* fileAddr = nullptr;
	BYTE* virtualAddr = nullptr;

	// Initialize pointers
	pDosHeader = nullptr;
	pFileHeader = nullptr;
	pOptionalHeader = nullptr;
	
	ret = PEReader("notepad.exe", &fileBuffer);
	ret = PEParser(fileBuffer);

	// memory allocation for a image buffer
	imgBuffer = (PMEMORYBASE)malloc(sizeof(BYTE) * pOptionalHeader->SizeOfImage);
	if (imgBuffer == nullptr) {
		printf("Failed to allocate memory.\n");
		exit(-1);
	}
	memset(imgBuffer, 0, sizeof(BYTE) * pOptionalHeader->SizeOfImage);
	
	// simulate memory allocation for image base
	pOptionalHeader->ImageBase = (DWORD)imgBuffer;

	// test for legal address of a section
	virtualAddr = (BYTE*)((DWORD)pOptionalHeader->ImageBase + p_section_header[0].VirtualAddress + 10);
	// test for illegal address of a section
	// virtualAddr = (BYTE*)((DWORD)pOptionalHeader->ImageBase + p_section_header[0].VirtualAddress - 10);
	fileAddr = VAToFOA(virtualAddr, fileBuffer);
	
	printf("Tools.TEST_VAToFOA:\n");
	printf("file buffer: %x\n", fileBuffer);
	printf("image buffer: %x\n", imgBuffer);
	printf("section[0].VirtualAddress: %x\n", p_section_header[0].VirtualAddress);
	printf("virtual address: %x\n", virtualAddr);
	printf("file address: %x\n", fileAddr);
	printf("\n");
}

void TEST_FileOperation() {
	STATUS ret;
	PMEMORYBASE newFileBuffer = nullptr;

	// Initialize pointers
	fileBuffer = nullptr;
	imageBuffer = nullptr;
	pDosHeader = nullptr;
	pFileHeader = nullptr;
	pOptionalHeader = nullptr;
	
	ret = PEReader("notepad.exe", &fileBuffer);
	ret = PEParser(fileBuffer);
	// printHeaders();
	ret = FileBufferToImageBuffer(fileBuffer, &imageBuffer);
	ret = ImageBufferToFileBuffer(imageBuffer, &newFileBuffer);
	ret = SaveBufferAsFile("new_notepad.exe", newFileBuffer);
}
```

Notice that `ImageBase` is set by system when the program is loaded into physical memory. In `TEST_VAToFOA`, we just imitate system to allocate a memory buffer, called image buffer. Thereby, `pOptionalHeader->ImageBase` should be the address we allocate, namely `imageBuffer`.

<EndMarkdown>