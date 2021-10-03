# PE Seg.3

## Table of Contents
- [Mapping](#mapping)
	- [FileBuffer to ImageBuffer](#filebuffertoimagebuffer)
	- [ImageBuffer to FileBuffer](#imagebuffertofilebuffer)

<TableEndMark>

## Mapping

Now we are going to map file buffer into image buffer. Following diagram will give us an intuition about them.

![File Buffer](codehome/src/img/backward/filebuffer.png)

![Image Buffer](codehome/src/img/backward/imagebuffer.png)

In previous notes, we have loaded an executable file, notepad.exe specifically, into our memory, which is termed file buffer. Meanwhile, we parse some important members, such as DOS Header, File Header, Optional PE Header, and Section Header. It's time to map data in file buffer to image buffer.

Notice that in image buffer, each section of data has been stretched since it is aligned by `FileAlignment` in file buffer and `SectionAlignment` in image buffer. The first problem is to find a pattern of transferring data from file buffer to image buffer.

It can be concluded as following steps: (assume that *x* is the address of data in image buffer)
- calculate offset to ImageBase, `x -= ImageBase`.
- locate which section it belongs to, `VirtualAddress[i] < x <= VirtualAddress[i] + misc.VirtualSize[i]`, where `i` means *i*th section.
- calculate offset to the beginning of the section, `x -= VirtualAddress[n]`, where `n` is the number of section it belongs to.
- locate the data block in file buffer, `x += PointerToRawData[n]`.

### FileBuffer to ImageBuffer

We reorganized programs in previous sections in a hierarchy way so that we are able to manage it conveniently and high-efficiently.

```c
// Global.h: we define global macro and type here.
#ifndef GLOBAL_H
#define GLOBAL_H

#define BYTE unsigned char
#define WORD unsigned short
#define DWORD unsigned int
#define PIMAGE_HEADER unsigned char*
#define nullptr NULL
#define DEBUG 0

#endif
```

```c
// ImageElement.h: this program defines basic element for storing entry of PE Headers
#ifndef IMAGEELEMENT_H
#define IMAGEELEMENT_H

#include <stdio.h>
#include "Global.h"

// Para.:
// @offset: offset to the base address of headers
// @length: the length of entry
// @val: store same as memory, aka. big endian, 48 3c 40 00
// @dword: store in 4-bytes format, 00403c48
typedef struct imageElement {
	size_t offset;
	size_t length;
	BYTE* val;
	DWORD dword;
} ImageElement;

// @baseAddrOfHeader: is a pointer, which will change as parsing different header
extern PIMAGE_HEADER baseAddrOfHeader;

void initImageElement(ImageElement* pEle, size_t offset, size_t length);
void printElement(char* prompt, ImageElement* pEle);

#endif
```

```c
// ImageElement.c
#include "ImageElement.h"

void initImageElement(ImageElement* pEle, size_t offset, size_t length) {
	BYTE* buffer = nullptr;

	pEle->offset = offset;
	pEle->length = length;
	
	// read as pointer
	buffer = (BYTE*)malloc(sizeof(BYTE) * sizeof(DWORD));
	memset(buffer, 0, sizeof(BYTE) * sizeof(DWORD));
	memcpy(buffer, baseAddrOfHeader + pEle->offset, pEle->length);
	
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
```

```c
// PEReader.h: this program will read file into file buffer and return the base address of file buffer
#ifndef PEREADER_H
#define PEREADER_H

#include <stdio.h>
#include "Global.h"

// Para.
// @filename: the full name of a PE file
BYTE* readPEFile(BYTE* filename);

#endif
```

```c
// PEReader.c
#include "PEReader.h"

unsigned char* readPEFile(BYTE* filename) {
	FILE *stream;
	size_t filesize = 0;
	int flag = 0;
	BYTE* fileBuffer = nullptr;
	
	if ((stream = fopen(filename, "rb")) != NULL) {
		// get file size
		fseek(stream, 0L, SEEK_END);
		filesize = ftell(stream);

		printf("%d\n", filesize);
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

		// memory read
		flag = fread(fileBuffer, sizeof(BYTE), filesize, stream);
		if (!flag) {
		    printf("Failed to read file.\n");
		    free(fileBuffer);
		    fclose(stream);
		    exit(-1);
		}
		
		fclose(stream);
		
		if (DEBUG) {
			printf("Filesize: %d\n", filesize);
			printf("fileBufferAddr: %x\n", fileBuffer);
			printf("\n");
		}

		return fileBuffer;
	}
	else {
		printf("ERROR: The file was not opened properly.\n");
		exit(-1);
	}
}
```

```c
// SectionHeader.h: since there are more than one file include it, we have to write a unique header file for defining section_header type.
#ifndef SECTIONHEADER_H
#define SECTIONHEADER_H

#include "ImageElement.h"

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

#endif
```

```c
// Main Program: PE Parser
// This program is going to read PE file from disk to file buffer
// in virtual memory, and then parses fields of the PE file.
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "Global.h"
#include "PEReader.h"
#include "ImageElement.h"
#include "Tools.h"

#define IMAGE_SIZEOF_SHORT_NAME 8

struct dosHeader{
	ImageElement e_magic;
	ImageElement e_lfanew;
} DOSHeader; 

struct fileHeader{
	ImageElement Machine;
	ImageElement NumberOfSections;
	ImageElement TimeDateStamp;
	ImageElement PointerToSymbolTable;
	ImageElement NumberOfSymbols;
	ImageElement SizeOfOptionalHeader;
	ImageElement Characteristics;
} FileHeader; 

struct optionalHeader{
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

IMAGE_SECTION_HEADER* p_section_header = nullptr;

// base of file buffer
PIMAGE_HEADER fileBase = nullptr;
// track base address of each header
PIMAGE_HEADER baseAddrOfHeader = nullptr;
// base of image buffer, simulate imageBase in system
PIMAGE_HEADER imageBase = nullptr;

void InitializeParserTable() {
	size_t number_of_sections = 0;
	size_t file_header_offset = 0;
	size_t size_of_a_section = 0x28;
	size_t i;

	baseAddrOfHeader = fileBase;

	// DOS Header
	initImageElement(&DOSHeader.e_magic, 0, 2);
	initImageElement(&DOSHeader.e_lfanew, 60, 4);
	
	// offset of PE Flag to DOS Header
	// sizeof PE flag is 4 bytes, which is '50 45 00 00'
	file_header_offset = DOSHeader.e_lfanew.dword + 4;
	baseAddrOfHeader += file_header_offset;

	// PE STD Header
	initImageElement(&FileHeader.Machine, 0, 2);
	initImageElement(&FileHeader.NumberOfSections, 2, 2);
	initImageElement(&FileHeader.TimeDateStamp, 4, 4);
	initImageElement(&FileHeader.PointerToSymbolTable, 8, 4);
	initImageElement(&FileHeader.NumberOfSymbols, 12, 4);
	initImageElement(&FileHeader.SizeOfOptionalHeader, 16, 2);
	initImageElement(&FileHeader.Characteristics, 18, 2);

	// change ptrAddr to Optional Header, the size of File Header is 20 bytes
	baseAddrOfHeader += 20;

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
	baseAddrOfHeader += FileHeader.SizeOfOptionalHeader.dword;

	if (DEBUG) {
		printf("value of ptrAddr is %x\n", (char)*baseAddrOfHeader);
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
		baseAddrOfHeader += size_of_a_section;
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
	fileBase = readPEFile("notepad.exe");
    PEParser();

    return 0;
}
```

Now we are going to write a function to simulate system to transfer data from file buffer into image buffer.

```c
// Tools.h: this program will transfer data in file buffer to image buffer
#ifndef TOOLS_H
#define TOOLS_H

#include <stdio.h>
#include "Global.h"
#include "SectionHeader.h"

extern PIMAGE_HEADER fileBase;

// translate relative virtual address(RVA) to file offset address(FOA) for each data
// in a simple word, copy by byte
BYTE* VAtoFOA(BYTE* virtualAddrOfData, BYTE* imgBase, BYTE* fileBase, IMAGE_SECTION_HEADER* p_section_header, int numberOfSections);

// the function will return imageBase which records the base address of image file
// copy in batch
BYTE* TransferToImageBuffer(BYTE* fileBase, int imgSize, int headerSize, IMAGE_SECTION_HEADER* p_section_header, int numberOfSections);

BYTE* TransferToFileBuffer(BYTE* imageBase, int fileSize, int headerSize, IMAGE_SECTION_HEADER* p_section_header, int numberOfSections);
void SaveAsFile(char* name, BYTE* fileBase, int fileSize);

void TestVAtoFOA(BYTE* fileBase, int imgSize, int headerSize, IMAGE_SECTION_HEADER* p_section_header, int numberOfSections);

#endif
```

```c
// Tools.c
#include "Tools.h"

int isInSection(int rva, int beginRVA, int endRVA) {
	if (rva >= beginRVA && rva <= endRVA) {
		return 1;
	}

	return 0;
}

BYTE* VAtoFOA(BYTE* virtualAddrOfData, BYTE* imgBase, BYTE* fileBase, IMAGE_SECTION_HEADER* p_section_header, int numberOfSections) {
	// calculate relative virtual address
	int i;
	int sectionNum = -1;
	int rva = virtualAddrOfData - imgBase;
	int offset = 0;
	BYTE* fileAddrOfData = nullptr;
	
	// judge which section it belongs to
	for (i = 0; i < numberOfSections; i++) {
		if (isInSection(rva, p_section_header[i].VirtualAddress.dword, p_section_header[i].VirtualAddress.dword + p_section_header[i].Misc.VirtualSize.dword)) {
			sectionNum = i;
			break;
		}
	}

	// throw error
	if (sectionNum == -1) {
		printf("Error: Data is not in legal range of any section.\n");
		exit(-1);
	}

	// calculate offset to the begin of the section
	offset = rva - p_section_header[sectionNum].VirtualAddress.dword;

	// get the address in file buffer
	fileAddrOfData = fileBase + p_section_header[sectionNum].PointerToRawData.dword + offset;
	
	return fileAddrOfData;
}

BYTE* TransferToImageBuffer(BYTE* fileBase, int imgSize, int headerSize, IMAGE_SECTION_HEADER* p_section_header, int numberOfSections) {
	// memory allocation for image buffer
	BYTE* imgBase = (BYTE*)malloc(sizeof(BYTE) * imgSize);
	size_t i;
	memset(imgBase, 0, sizeof(BYTE) * imgSize);
	
	// copy headers
	memcpy(imgBase, fileBase, sizeof(BYTE) * headerSize);
	
	if (DEBUG) {
		printf("imgBase: %x\n", imgBase);
		printf("fileBase: %x\n", fileBase);
		for (i = 0; i < numberOfSections; i++) {
			printf("Section[%d] VirtualAddr: %x\n", i, &imgBase[p_section_header[i].VirtualAddress.dword]);
			printf("Section[%d] FileAddr: %x\n", i, &fileBase[p_section_header[i].PointerToRawData.dword]);
		}
	}

	// copy sections
	for (i = 0; i < numberOfSections; i++) {
		memcpy(&imgBase[p_section_header[i].VirtualAddress.dword], &fileBase[p_section_header[i].PointerToRawData.dword], sizeof(BYTE) * p_section_header[i].SizeOfRawData.dword);
	}

	return imgBase;
}

void TestVAtoFOA(BYTE* fileBase, int imgSize, int headerSize, IMAGE_SECTION_HEADER* p_section_header, int numberOfSections) {
    BYTE* fileAddr = nullptr;
	BYTE* virtualAddr = nullptr;

	// memory allocation
	BYTE* imgBase = (BYTE*)malloc(sizeof(BYTE) * imgSize);
	memset(imgBase, 0, sizeof(BYTE) * imgSize);
	
	// test for legal address of a section
	virtualAddr = imgBase + p_section_header[0].VirtualAddress.dword + 10;
	// test for address out of range
	// virtualAddr = imgBase + p_section_header[0].VirtualAddress.dword - 10;
	fileAddr = RAVtoFOA(virtualAddr, imgBase, fileBase, p_section_header, numberOfSections);
	
	printf("ImageBase: %x\n", imgBase);
	printf("FileBase: %x\n", fileBase);
	printf("Virtual Address: %x\n", virtualAddr);
	printf("File Address: %x\n", fileAddr);
}
```

### ImageBuffer to FileBuffer

After transferring from file buffer to image buffer, how about do it reversely.

The first problem is how to calculate memory size of file buffer to allocate. From the diagram above, we are able to figure out that `sizeof(file buffer) = SizeOfHeaders + Section[i].SizeOfRawData`, where `i = 0, 1, 2, ...`.

Now let's try it!

First we need two auxiliary functions, one is to calculate memory size of file buffer and the other is to save file buffer as a file.

```c
// main.c
int CalculateFileSize() {
	int filesize = 0;
	int i;
	filesize += OptionalHeader.SizeOfHeaders.dword;
	for (i = 0; i < FileHeader.NumberOfSections.dword; i++) {
		filesize += p_section_header[i].SizeOfRawData.dword;
	}

	return filesize;
}
```

```c
// Tools.c
void SaveAsFile(char* filename, BYTE* fileBase, int fileSize) {
	FILE *stream;
	int flag = 0;
	if ((stream = fopen(filename, "wb")) != NULL) {
		flag = fwrite(fileBase, sizeof(BYTE), fileSize, stream);

		if (!flag) {
			printf("Failed to write file.\n");
			fclose(stream);
			exit(-1);
		}

		fclose(stream);
	}
	else {
		printf("Failed to open a new file.\n");
		exit(-1);
	}
}
```

In fact, reversed function is very simple, which is slightly different from `TransferToImageBuffer`.

```c
// Tools.c:
BYTE* TransferToFileBuffer(BYTE* imageBase, int fileSize, int headerSize, IMAGE_SECTION_HEADER* p_section_header, int numberOfSections) {
	int i;
	// memory allocation for file buffer
	BYTE* fileBase = (BYTE*)malloc(sizeof(BYTE) * fileSize);
	memset(fileBase, 0, sizeof(BYTE) * fileSize);

	// copy headers
	memcpy(fileBase, imageBase, sizeof(BYTE) * headerSize);

	// copy sections: the only difference from above
	for (i = 0; i < numberOfSections; i++) {
		memcpy(&fileBase[p_section_header[i].PointerToRawData.dword], &imageBase[p_section_header[i].VirtualAddress.dword], sizeof(BYTE) * p_section_header[i].SizeOfRawData.dword);
	}

	return fileBase;
}
```

Now let's test our programs, the program will do following process - read file into memory(file buffer), map data from file buffer to image buffer, map data from image buffer to a new file buffer, and at last save new file buffer as a file.

```c
int main(int argc, char* argv[]) {
	BYTE* fileBaseNew = nullptr;
	int filesize = 0;

    // read file into file buffer
	fileBase = readPEFile("notepad.exe");

    // parse headers	
    PEParser();

    // map file buffer to image buffer
	imageBase = TransferToImageBuffer(fileBase, OptionalHeader.SizeOfImage.dword, OptionalHeader.SizeOfHeaders.dword, p_section_header, FileHeader.NumberOfSections.dword);
	
    // map image buffer to a new file buffer
    filesize = CalculateFileSize();
	fileBaseNew = TransferToFileBuffer(imageBase, filesize, OptionalHeader.SizeOfHeaders.dword, p_section_header, FileHeader.NumberOfSections.dword);

    // save as a new file
	SaveAsFile("newNotePad.exe", fileBase, filesize);

    return 0;
}
```

<EndMarkdown>