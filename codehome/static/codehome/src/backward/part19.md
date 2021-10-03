# PE Seg.10

## Table of Contents

- [Move of Import Table](#moveofimporttable)
	- [Which to Move](#whichtomove)
	- [How to Move](#howtomove)
	- [C Program](#cprogram)
- [IAT and BRT](#iatandbrt)
	- [Add DLL to Import Table](#adddlltoimporttable)
	- [Entry Main](#entrymain)
    - [Injection](#injection)

<TableEndMark>

## Move of Import Table

### Which to Move

The first question is which table is able to be moved.

- Import Directory: or say Image Import Descriptor, Yes.
- Import Lookup(Name) Table (INT) attached to each descriptor: Yes.
- Import Address Table (IAT) attached to each descriptor : No! Since we don't know how many function or instructions refer to the IAT directly or indirectly. For example, after dll is put into memory, the loader will go to fix IAT, whose address, however, is pre-compiled in the executable, remember the experiment in IAT part of last note, `0042a2ac` is pre-compiled as a placeholder, which points to IAT.

### How to Move

The direct way to do it is to create a section first, and put related tables in that new section. The advantage of the method is that we do not have to consider whether there is enough space left in exist sections.

- Allocate a new section.
- Move all image import descriptors to a sequence of memory of the new section. (do NOT forget to add all-zero end flag)
- Move import lookup table and name table of each image import descriptor to the place after the end of the end flag, meanwhile updating name address of import lookup table, and finally update relative virtual addresses in responding descriptor. (do NOT forget to add all-zero end flag to two tables)

When moving name table, we have to update each entry (0 and 31-bit RVA) of import lookup table.

Notice that the struct of name table is as follows,

```c
typedef struct _IMAGE_IMPORT_BY_NAME {			
    WORD    Hint;			
    BYTE    Name[1];			
} IMAGE_IMPORT_BY_NAME, *PIMAGE_IMPORT_BY_NAME;			
```

`Hint` could be set as zero since it is useless because function address is searched by name rather than hint in general, and then copy name.

- Modify Data Directory: to the new relative virtual address.

### C Program

```c
// Tools.h
// MoveImportDirectoryToNewAddress:
//     The function will move base relocation table to a given address.
// @location: the location where to put import directory.
// @buffer: the buffer to be operated.
// Assume that there are at least 3000h memory space available
STATUS MoveImportDirectoryToNewAddress(IN BYTE* location, IN PMEMORYBASE buffer);

// TEST_MoveImportDirectoryToNewAddress():
//     This function will test the validation of MoveImportDirectoryToNewAddress.
void TEST_MoveImportDirectoryToNewAddress();
```

```c
// Tools.c
STATUS MoveImportDirectoryToNewAddress(IN BYTE* location, IN PMEMORYBASE buffer) {
	// Assume that size of raw data is 0x3000
	// TODO: move all image import descriptors to location
	IMAGE_IMPORT_DESCRIPTOR* pDescriptor = pImportDirectory;
	IMAGE_IMPORT_DESCRIPTOR* newDescriptor = (IMAGE_IMPORT_DESCRIPTOR*)location;
	IMAGE_THUNK_DATA32* newLookupTable = nullptr;
	IMAGE_THUNK_DATA32* pLookupTable = nullptr;
	IMAGE_IMPORT_BY_NAME* newName = nullptr;
	IMAGE_IMPORT_BY_NAME* pName = nullptr;
	size_t i;
	DWORD ordinal_mask = 0x80000000;
	size_t END_FLAG = 0;
	DWORD newNameAddr = 0;
	DWORD newOriginalThunkAddr = 0;
	DWORD OFFSET = 0x1000;

	while (pDescriptor->OriginalFirstThunk != 0) {
		memcpy(newDescriptor, pDescriptor, sizeof(IMAGE_IMPORT_DESCRIPTOR));
		
		// update pointer
		newDescriptor++;
		pDescriptor++;
	}

	// add zero-padding end flag
	memset(newDescriptor, 0, sizeof(IMAGE_IMPORT_DESCRIPTOR));
	newDescriptor++;

	// relay end address to lookup table, and reset to start of descriptor
	newDescriptor = (IMAGE_IMPORT_DESCRIPTOR*)location;

	// TODO: 
	// 1. move lookup table at 0x1000 offset to the begin of the section.
	// 2. move name table at 0x2000 offset to the begin of the section.
	newLookupTable = (IMAGE_THUNK_DATA32*)((DWORD)location + OFFSET);
	newName = (IMAGE_IMPORT_BY_NAME*)((DWORD)location + OFFSET * 2);	
	
	while (newDescriptor->OriginalFirstThunk != 0) {
		pLookupTable = (IMAGE_THUNK_DATA32*)RVAToFOA((BYTE*)newDescriptor->OriginalFirstThunk, fileBuffer);
		for (i = 0; pLookupTable[i].u1.Ordinal != 0; i++) {
			if (pLookupTable[i].u1.Ordinal & ordinal_mask) {
				// reference by ordinal
				// TODO: 
				// 1. copy name to new name (ordinal with size of DWORD)
				pName = (IMAGE_IMPORT_BY_NAME*)RVAToFOA((BYTE*)pLookupTable[i].u1.Ordinal, fileBuffer);
				memcpy(newName, pName, sizeof(DWORD));
				// 2. update new lookup table
				newNameAddr = (DWORD)FOAToRVA((BYTE*)&newName->Hint, fileBuffer);
				memcpy(&newLookupTable[i].u1.Ordinal, &newNameAddr, sizeof(DWORD));
				// 3. update pointer: consider that each entry of name table has various length
				newName = (IMAGE_IMPORT_BY_NAME*)((DWORD)newName + sizeof(WORD));
			}
			else {
				// reference by name
				// TODO: 
				// 1. copy name to new name
				pName = (IMAGE_IMPORT_BY_NAME*)RVAToFOA((BYTE*)pLookupTable[i].u1.Ordinal, fileBuffer);
				// notice that: hint(WORD) + name(String) + 1('\0')
				memcpy(newName, &pName->Hint, sizeof(WORD) + strlen((char*)&pName->Name) + 1);
				// 2. update new lookup table
				newNameAddr = (DWORD)FOAToRVA((BYTE*)&newName->Hint, fileBuffer);
				memcpy(&newLookupTable[i].u1.Ordinal, &newNameAddr, sizeof(DWORD));
				// 3. update pointer:
				newName = (IMAGE_IMPORT_BY_NAME*)((DWORD)newName + sizeof(WORD) + strlen((char*)&pName->Name) + 1);
			}
		}

		// add end flag to lookup table and name table
		memcpy(newName, &END_FLAG, sizeof(DWORD));
		memcpy(&newLookupTable[i], &END_FLAG, sizeof(DWORD));
		
		// update rva in import descriptor
		newOriginalThunkAddr = (DWORD)FOAToRVA((BYTE*)newLookupTable, fileBuffer);
		newDescriptor->OriginalFirstThunk = newOriginalThunkAddr;
		
		// update newLookupTable and newName for next descriptor
		newLookupTable = (IMAGE_THUNK_DATA32*)((DWORD)&newLookupTable[i] + sizeof(DWORD));
		newName = (IMAGE_IMPORT_BY_NAME*)((DWORD)newName + sizeof(DWORD));
		newDescriptor++;
	}

	// modify relative virtual address in data directory
	pDirectory[1].VirtualAddress = (DWORD)FOAToRVA(location, fileBuffer);
	// update global variable
	pImportDirectory = (IMAGE_IMPORT_DESCRIPTOR*)location;

	return 0;
}

void TEST_MoveImportDirectoryToNewAddress() {
	STATUS ret;
	IMAGE_SECTION_HEADER* newSection = nullptr;
	PMEMORYBASE newFileBuffer = nullptr;
	char* name = ".idata";
	BYTE* location = nullptr;

	// Initialize global pointers
	fileBuffer = nullptr;
	imageBuffer = nullptr;
	pDosHeader = nullptr;
	pFileHeader = nullptr;
	pOptionalHeader = nullptr;

	ret = PEReader(FILE_IN, &fileBuffer);
	ret = PEParser(fileBuffer);

	newSection = (IMAGE_SECTION_HEADER*)malloc(sizeof(IMAGE_SECTION_HEADER));
	memset(newSection, 0, sizeof(IMAGE_SECTION_HEADER));
	memcpy(&newSection->Name, name, SIZEOF_SECTION_NAME);
	newSection->Misc.PhysicalAddress = 0x00003000;

	ret = AddSectionToBuffer(fileBuffer, newSection, &newFileBuffer);
	// relay to fileBuffer;
	free(fileBuffer);
	fileBuffer = newFileBuffer;
	newFileBuffer = nullptr;
	// fileBuffer has to be parsed once again, since fileBuffer has changed
	ret = PEParser(fileBuffer);

	printf("original FOA of import directory: %x\n", (DWORD)RVAToFOA((BYTE*)pDirectory[1].VirtualAddress, fileBuffer));
	
	location = (BYTE*)((DWORD)fileBuffer + p_section_header[pFileHeader->NumberOfSections - 1].PointerToRawData);
	ret = MoveImportDirectoryToNewAddress(location, fileBuffer);
	
	printf("new FOA of import directory: %x\n", (DWORD)RVAToFOA((BYTE*)pDirectory[1].VirtualAddress, fileBuffer));

	printImportDirectory();
}
```

## IAT and BRT

Now we will go deep further into the distinction between import address table and base relocation table.

- Base Relocation Table: the loader will fix direct references (addresses) within the file to which base relocation table (BRT) belongs by iterating on BRT, which records every address that need to be modified.
- Import Address Table: the loader will fix the addresses in import address table (IAT), whose item responds to an imported function, not direct references (addresses). Yet how to locate direct references which points to IAT? The answer is that every direct reference is pointing to the item of IAT, which responds to the imported function it is going to call.

![IAT v.s. BRT](codehome/src/img/backward/IATvsBRT.png)

## Add DLL to Import Table

### Entry Main

The main function of dll, which is termed entry main, is slightly different from one of the executable. The entry main will be called when the dll is loaded and unloaded from memory.

```bash
# Structure of project DllMethod
# Dependency: caller -> callee
DllMethod.h ---> DLLMethod.cpp (DllMain())
    |
    |---> Tools.h ---> Tools.cpp ( Init(),
                                   Destroy(),
                                   foo() )
```

```c
// DLL with definition of entry main
// DLLMethod.h:

#if !defined(AFX_DLLMETHOD_H__72A886A0_44E1_4ABA_BAB3_8D19A9BB1F9A__INCLUDED_)
#define AFX_DLLMETHOD_H__72A886A0_44E1_4ABA_BAB3_8D19A9BB1F9A__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#include <windows.h>
#include "Tools.h"

BOOL APIENTRY DllMain( HANDLE hModule, 
                       DWORD  ul_reason_for_call, 
                       LPVOID lpReserved
					 );

#endif // !defined(AFX_DLLMETHOD_H__72A886A0_44E1_4ABA_BAB3_8D19A9BB1F9A__INCLUDED_)
```

```c
// Tools.h:
#if !defined(AFX_TOOLS_H__6975B5E5_AF40_4D78_8410_F0700EF71DE0__INCLUDED_)
#define AFX_TOOLS_H__6975B5E5_AF40_4D78_8410_F0700EF71DE0__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#include <windows.h>

// private function used in dll
void Init();
void Destroy();

// public function 
extern "C" _declspec(dllexport) void foo();  

#endif // !defined(AFX_TOOLS_H__6975B5E5_AF40_4D78_8410_F0700EF71DE0__INCLUDED_)
```

```c
// DLLMethod.cpp:
#include "DLLMethod.h"

BOOL APIENTRY DllMain( HANDLE hModule, 
                       DWORD  ul_reason_for_call, 
                       LPVOID lpReserved
					 ) {
	switch (ul_reason_for_call) {
	case DLL_PROCESS_ATTACH:
		Init();
		break;
	case DLL_PROCESS_DETACH:
		Destroy();
		break;
    }
    return TRUE;
}
```

```c
// Tools.cpp
#include "Tools.h"

void Init() {
	MessageBox(0, "Init", "Init", MB_OK);
}

void Destroy() {
	MessageBox(0, "Destroy", "Destroy", MB_OK);
}

void foo() {
	MessageBox(0, "Execution: foo()", "Execution: foo()", MB_OK);
}
```

Then write a test program try to use `DLLMethod.dll`.

```c
// implicit reference
#include <stdio.h>
#pragma comment(lib, "DLLMethod.lib")

extern "C" _declspec(dllimport) void foo();

int main(int argc, char* argv[]) {
	
	foo();

	return 0;
}
```

```c
// explicit reference
#include <stdio.h>
#include <windows.h>

typedef void (*pFunc)();

int main(int argc, char* argv[]) {
	pFunc foo;

	HINSTANCE hModule = LoadLibrary("DLLMethod.dll");
	foo = (pFunc)GetProcAddress(hModule, "foo");

	foo();

    FreeLibrary(hModule);

	return 0;
}
```

### Injection

Now we will inject dll above to notepad. The expected result is that message box will appear twice when loading dll and unloading dll respectively.

```c
// Tools.h:
// AddNewImportDirectory:
//     The function will add a new import directory to a given address.
// Notice that before running the function, we'd better to move import directory to a safe place so that
// there is enough space for new import directory.
// @location: the location where to insert import directory, which is a foa. The location must before end flag, not 
// right after end flag.
// @dllName: the name of dll.
// @pNewDirectory: a pointer to an import directory to be inserted.
// @pImportLookupTable: a pointer to an import lookup table to be inserted. 
// @pNameTable: a pointer to a name table responding to import lookup table above.
// @pImportAddressTable: IGNORED, since it is same with import lookup table. The function will make a copy of import lookup
// table as IAT.
// The responding import lookup table, hint table, and import address table will be inserted after new import directory.
// Therefore take care of the size of space available. 
STATUS AddNewImportDirectory(IN BYTE* location, char* dllName, IN IMAGE_IMPORT_DESCRIPTOR* pNewDirectory, IN IMAGE_THUNK_DATA32* pImportLookupTable, IN IMAGE_IMPORT_BY_NAME* pNameTable);

// TEST_AddNewImportDirectory():
//     This function will test the validation of AddNewImportDirectory.
void TEST_AddNewImportDirectory();
```

```c
// Tools.cpp:
////////////////////////////////////////////
// Helper Functions for AddNewImportDirectory
////////////////////////////////////////////

// return end address
BYTE* AddLookupTable(IN BYTE* location, IN IMAGE_THUNK_DATA32* pImportLookupTable) {
	// copy data
	while (pImportLookupTable->u1.Ordinal != 0) {
		memcpy(location, pImportLookupTable, sizeof(IMAGE_THUNK_DATA32));
		pImportLookupTable++;
		location += sizeof(IMAGE_THUNK_DATA32);
	}
	
	// copy end flag
	memset(location, 0, sizeof(IMAGE_THUNK_DATA32));
	location += sizeof(IMAGE_THUNK_DATA32);

	return location;
}

BYTE* AddNameTable(IN BYTE* location, IN IMAGE_IMPORT_BY_NAME* pNameTable) {
	// copy data
	// while (pNameTable->Name != 0): this is false since Name is the size of byte,
	// which only saves the first character of a name string.
	while (strlen((char*)&pNameTable->Name) != 0) {
		memcpy(location, pNameTable, sizeof(IMAGE_IMPORT_BY_NAME));
		pNameTable++;
		location += sizeof(IMAGE_IMPORT_BY_NAME);
	}

	// copy end flag
	memset(location, 0, sizeof(IMAGE_IMPORT_BY_NAME));
	location += sizeof(IMAGE_IMPORT_BY_NAME);

	return location;
}

BYTE* AddImportAddressTable(IN BYTE* location, IN IMAGE_THUNK_DATA32* pImportAddressTable) {
	// copy data
	while (pImportAddressTable->u1.Ordinal != 0) {
		memcpy(location, pImportAddressTable, sizeof(IMAGE_THUNK_DATA32));
		pImportAddressTable++;
		location += sizeof(IMAGE_THUNK_DATA32);
	}
	
	// copy end flag
	memset(location, 0, sizeof(IMAGE_THUNK_DATA32));
	location += sizeof(IMAGE_THUNK_DATA32);

	return location;
}

STATUS AddNewImportDirectory(IN BYTE* location, char* dllName, IN IMAGE_IMPORT_DESCRIPTOR* pNewDirectory, IN IMAGE_THUNK_DATA32* pImportLookupTable, 
							 IN IMAGE_IMPORT_BY_NAME* pNameTable) {
	IMAGE_IMPORT_DESCRIPTOR* pDescriptor = (IMAGE_IMPORT_DESCRIPTOR*)location;
	IMAGE_THUNK_DATA32* pNewLookupTable = nullptr;
	IMAGE_IMPORT_BY_NAME* pNewNameTable = nullptr;
	IMAGE_THUNK_DATA32* pNewAddressTable = nullptr;
	BYTE* endAddr = nullptr;
	BYTE* nameAddr = nullptr;
	size_t offset = 10;

	// TODO: copy new directory to location
	// hint: *2 since the last is used as zero-padding end flag
	memset(location, 0, sizeof(IMAGE_IMPORT_DESCRIPTOR) * 2);
	memcpy(pDescriptor, pNewDirectory, sizeof(IMAGE_IMPORT_DESCRIPTOR));
	endAddr = location + sizeof(IMAGE_IMPORT_DESCRIPTOR) * 2;

	// TODO: copy related tables and update addresses in descriptor
	// copy import lookup table
	pNewLookupTable = (IMAGE_THUNK_DATA32*)(endAddr + offset);
	pDescriptor->OriginalFirstThunk = (DWORD)FOAToRVA(endAddr + offset, fileBuffer);
	endAddr = AddLookupTable(endAddr + offset, pImportLookupTable);
	
	// copy and update dll name
	nameAddr = endAddr + offset;
	strcpy((char*)nameAddr, dllName);
	pDescriptor->Name = (DWORD)FOAToRVA(nameAddr, fileBuffer);
	endAddr += offset + strlen(dllName);

	// copy name table
	pNewNameTable = (IMAGE_IMPORT_BY_NAME*)(endAddr + offset);
	endAddr = AddNameTable(endAddr + offset, pNameTable);

	// update lookup table: assume that the size of lookup table equals that of name table
	// do NOT forget to set highest significant bit as 1 to declare that it is referred by ordinal
	while (pNewLookupTable->u1.Ordinal != 0) {
		pNewLookupTable->u1.Ordinal = (DWORD)FOAToRVA((BYTE*)pNewNameTable, fileBuffer) | 0x80000000;
		pNewLookupTable++;
		pNewNameTable++;
	}
	
	// copy import address table
	pDescriptor->FirstThunk = (DWORD)FOAToRVA(endAddr + offset, fileBuffer);
	endAddr = AddImportAddressTable(endAddr + offset, pImportLookupTable);

	return 0;
}
```

```c
// Tools.cpp:
void TEST_AddNewImportDirectory() {
	STATUS ret;

	IMAGE_SECTION_HEADER* newSection = nullptr;
	PMEMORYBASE newFileBuffer = nullptr;
	char* name = ".idata";
	BYTE* location = nullptr;
	IMAGE_IMPORT_DESCRIPTOR* pDescriptor = nullptr;

	size_t numOfFunctions = 4;
	IMAGE_IMPORT_DESCRIPTOR* newDirectory = nullptr;
	IMAGE_THUNK_DATA32* newLookupTable = nullptr;
	IMAGE_IMPORT_BY_NAME* newNameTable = nullptr;
	
	// Initialize global pointers
	fileBuffer = nullptr;
	imageBuffer = nullptr;
	pDosHeader = nullptr;
	pFileHeader = nullptr;
	pOptionalHeader = nullptr;

	ret = PEReader(FILE_IN, &fileBuffer);
	ret = PEParser(fileBuffer);
	
	// TODO: create a new section
	newSection = (IMAGE_SECTION_HEADER*)malloc(sizeof(IMAGE_SECTION_HEADER));
	memset(newSection, 0, sizeof(IMAGE_SECTION_HEADER));
	memcpy(&newSection->Name, name, SIZEOF_SECTION_NAME);
	newSection->Misc.PhysicalAddress = 0x00003000;
	
	ret = AddSectionToBuffer(fileBuffer, newSection, &newFileBuffer);
	// relay to fileBuffer;
	free(fileBuffer);
	fileBuffer = newFileBuffer;
	newFileBuffer = nullptr;
	// fileBuffer has to be parsed once again, since fileBuffer has changed
	ret = PEParser(fileBuffer);

	// TODO: move import directory table to new section
	location = (BYTE*)((DWORD)fileBuffer + p_section_header[pFileHeader->NumberOfSections - 1].PointerToRawData);
	ret = MoveImportDirectoryToNewAddress(location, fileBuffer);
	
	// TODO: move new import table to new section
	// construct a descriptor: reserved end flag
	newDirectory = (IMAGE_IMPORT_DESCRIPTOR*)malloc(sizeof(IMAGE_IMPORT_DESCRIPTOR) * 2);
	memset(newDirectory, 0, sizeof(IMAGE_IMPORT_DESCRIPTOR) * 2);
	memset(newDirectory, 0x11, sizeof(IMAGE_IMPORT_DESCRIPTOR));

	// construct lookup table: reserved end flag
	newLookupTable = (IMAGE_THUNK_DATA32*)malloc(sizeof(IMAGE_THUNK_DATA32) * (numOfFunctions + 1));
	memset(newLookupTable, 0, sizeof(IMAGE_THUNK_DATA32) * (numOfFunctions + 1));
	memset(newLookupTable, 0x11, sizeof(IMAGE_THUNK_DATA32) * numOfFunctions);

	// construct name table (by ordinal by default): reserved end flag
	newNameTable = (IMAGE_IMPORT_BY_NAME*)malloc(sizeof(IMAGE_IMPORT_BY_NAME) * (numOfFunctions + 1));
	memset(newNameTable, 0, sizeof(IMAGE_IMPORT_BY_NAME) * (numOfFunctions + 1));
	memset(newNameTable, 0x11, sizeof(IMAGE_IMPORT_BY_NAME) * numOfFunctions);
	
	// find the end of descriptor and the location points to the beginning address of end flag 
	pDescriptor = (IMAGE_IMPORT_DESCRIPTOR*)RVAToFOA((BYTE*)pDirectory[1].VirtualAddress, fileBuffer);
	while (pDescriptor->OriginalFirstThunk != 0) {
		pDescriptor++;
	}
	location = (BYTE*)pDescriptor;
	
	char* dllname = "DLLMethod.dll";
	ret = AddNewImportDirectory(location, dllname, newDirectory, newLookupTable, newNameTable);
	
	printImportDirectory();
	// save as a file
	ret = SaveBufferAsFile("injectedNotepad.exe", fileBuffer);
	
	free(fileBuffer);
}

```

<EndMarkdown>