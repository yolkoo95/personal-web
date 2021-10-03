# PE Seg.9

## Table of Contents
- [Import Data Section](#importdatasection)
	- [Import Directory Table](#importdirectorytable)
	- [Import Lookup Table](#importlookuptable)
	- [Name Table](#nametable)
	- [Import Address Table](#importaddresstable)
	- [Relationship](#relationship)
	- [Traverse Import Tables](#traverseimporttables)
- [IAT](#iat)
- [Bound Import](#boundimport)
	- [Introduction](#introduction)
	- [Structure](#structure)
	- [Traverse Bound Import Table](#traverseboundimporttable)

<TableEndMark>

## Import Data Section

Think from human perspective, if we want to offer some services for others, we have to let clients know what servers they are able to get. That's what export directory does -- providing function list. As a client, we also have to let clients know what our need is, so we have to offer a list to tell loader which function we have to use from server (i.e. dlls). This is the mission of import directory.

All image files that import symbols, including virtually all executable (EXE) files, have an `.idata` section. The section contains some tables we will discuss in the following.

### Import Directory Table

The import information begins with the import directory table, which describes the remainder of the import information. The import directory table contains address information that is used to resolve fixup references to the entry points within a DLL image. The import directory table consists of an array of import directory entries, one entry for each DLL to which the image refers. The last directory entry is empty (filled with null values), which indicates the end of the directory table.

```c
typedef struct _IMAGE_IMPORT_DESCRIPTOR {				
    union {				
        DWORD   Characteristics;           				
        DWORD   OriginalFirstThunk;         				
    };				
    DWORD   TimeDateStamp;               				
    DWORD   ForwarderChain;              				
    DWORD   Name;				
    DWORD   FirstThunk;                 				
} IMAGE_IMPORT_DESCRIPTOR;				
typedef IMAGE_IMPORT_DESCRIPTOR* PIMAGE_IMPORT_DESCRIPTOR;
```

| Offset | Size | Field | Description |
| :---: | :---: | :---: | :---: |
| 0 | 4 | Import Lookup Table RVA (Characteristics) | The RVA of the import lookup table. This table contains a name or ordinal for each import. (The name "Characteristics" is used in Winnt.h, but no longer describes this field.) |
| 4 | 4 | Time/Date Stamp | The stamp that is set to zero until the image is bound. After the image is bound, this field is set to the time/data stamp of the DLL. |
| 8 | 4 | Forwarder Chain | The index of the first forwarder reference. |
| 12 | 4 | Name RVA | The address of an ASCII string that contains the name of the DLL. This address is relative to the image base. |
| 16 | 4 | Import Address Table RVA (Thunk Table, IAT) | The RVA of the import address table. *The contents of this table are identical to the contents of the import lookup table until the image is bound.* | 

### Import Lookup Table

An import lookup table is an array of 32-bit numbers for PE32 or an array of 64-bit numbers for PE32+. Each entry uses the bit-field format that is described in the following table. In this format, bit 31 is the most significant bit for PE32 and bit 63 is the most significant bit for PE32+. The collection of these entries describes all imports from a given DLL. The last entry is set to zero (NULL) to indicate the end of the table.

```c
typedef struct _IMAGE_THUNK_DATA32 {				
    union {				
        PBYTE  ForwarderString;				
        PDWORD Function;				
        DWORD Ordinal;				
        PIMAGE_IMPORT_BY_NAME  AddressOfData;				
    } u1;				
} IMAGE_THUNK_DATA32;				
typedef IMAGE_THUNK_DATA32* PIMAGE_THUNK_DATA32;				
```

| Bit(s) | Size | Bit Field | Description | 
| :---: | :---: | :---: | :---: |
| 31/63 | 1 | Ordinal/Name Flag | If this bit is set, import by ordinal. Otherwise, import by name. Bit is masked as 0x80000000 for PE32. | 
| 15-0 | 16 | Ordinal Number | A 16-bit ordinal number. This field is used only if the Ordinal/Name Flag bit field is 1 (import by ordinal). Bits 30-15 or 62-15 must be 0. | 
| 30-0 | 31 | Hint/Name Table RVA | A 31-bit RVA of a hint/name table entry. This field is used only if the Ordinal/Name Flag bit field is 0 (import by name). For PE32+ bits 62-31 must be zero. |

### Name Table

One name(hint) table suffices for the entire import section. Each entry in the name(hint) table has the following format:

```c
typedef struct _IMAGE_IMPORT_BY_NAME {			
    WORD    Hint;			
    BYTE    Name[1];			
} IMAGE_IMPORT_BY_NAME, *PIMAGE_IMPORT_BY_NAME;			
```

| Offset | Size | Field | Description |
| :---: | :---: | :---: | :---: |
| 0 | 2 | Hint | An index into the export name pointer table. A match is attempted first with this value. If it fails, a binary search is performed on the DLL's export name pointer table. |
| 2 | Variable | Name | An ASCII string that contains the name to import. This is the string that must be matched to the public name in the DLL. This string is case sensitive and terminated by a null byte. |
| * | 0 or 1 | Pad | A trailing zero-pad byte that appears after the trailing null byte, if necessary, to align the next entry on an even boundary. |

### Import Address Table

The structure and content of the import address table are identical to those of the import lookup table, until the file is bound. During binding, the entries in the import address table are overwritten with the 32-bit (for PE32) or 64-bit (for PE32+) addresses of the symbols that are being imported. **These addresses are the actual memory addresses of the symbols, although technically they are still called "virtual addresses"**. The loader typically processes the binding.

### Relationship

After introducing each table, how they are related to each other?

![Relationship among Tables](codehome/src/img/backward/ImportTableRelationship.png)

- Import Lookup Table: is an array of IMAGE_THUNK_DATA, which is a union of ordinal or name RVA.
- Hint in IMAGE_THUNK_DATA: is just an index of that function in name pointer table. we have to look for ordinal in name ordinal table, which has the same index.

![Index Function Address](codehome/src/img/backward/relationship.png)

- IAT: is bound by loader when loading program into memory.

### Traverse Import Tables

Now let's print information of import tables in C:

```c
// Global.h: define table structs
///////////////////////////////
// Import Table - Begin

typedef struct image_import_descriptor {				
    union {				
        DWORD   Characteristics;           				
        DWORD   OriginalFirstThunk;         				
    };				
    DWORD   TimeDateStamp;               				
    DWORD   ForwarderChain;              				
    DWORD   Name;				
    DWORD   FirstThunk;                 				
} IMAGE_IMPORT_DESCRIPTOR;
IMAGE_IMPORT_DESCRIPTOR* pImportDirectory;

typedef struct image_thunk_data32 {				
    union {				
        BYTE*  ForwarderString;				
        DWORD* Function;				
        DWORD Ordinal;				
        struct IMAGE_IMPORT_BY_NAME*  AddressOfData;				
    } u1;				
} IMAGE_THUNK_DATA32;
IMAGE_THUNK_DATA32* pImportLookupTable;
IMAGE_THUNK_DATA32* pImportAddressTable;

typedef struct image_import_by_name {			
    WORD    Hint;			
    BYTE    Name[1];			
} IMAGE_IMPORT_BY_NAME;
IMAGE_IMPORT_BY_NAME* pNameTable;

// Import Table - End
///////////////////////////////
```

```c
// PEParser.h:
// printImportDirectory:
//     The function will print export directory, import lookup table, import address table, and name table.
void printImportDirectory();

// TEST_PrintImportDirectoryTable():
//     This function will test the print of import directory table.
void TEST_PrintImportDirectoryTable();
```

```c
// PEParser.c:
void printImportDirectory() {
	size_t i, j;
	WORD* pOrdinal = nullptr;
	DWORD ordinal_mask = 0x80000000;
	IMAGE_IMPORT_BY_NAME* pName = nullptr;
	IMAGE_IMPORT_DESCRIPTOR* pImportDirectoryTable = pImportDirectory;

	printf("======Import Directory======\n");
	for (i = 0; pImportDirectoryTable->OriginalFirstThunk != 0; i++) {
		printf("Import Directory Table [%d]:\n", i);
		printf("Import Lookup Table RVA: %x\n", pImportDirectory[i].OriginalFirstThunk);
		printf("Time/Date Stamp: %x\n", pImportDirectory[i].TimeDateStamp);
		printf("Forwarder Chain: %x\n", pImportDirectory[i].ForwarderChain);
		printf("DLL RVA: %x, Name: %s\n", pImportDirectory[i].Name, RVAToFOA((BYTE*)pImportDirectory[i].Name, fileBuffer));
		printf("Import Address Table RVA: %x\n", pImportDirectory[i].FirstThunk);
		printf("\n");
		
		pImportLookupTable = (IMAGE_THUNK_DATA32*)RVAToFOA((BYTE*)pImportDirectory[i].OriginalFirstThunk, fileBuffer);
		printf("Import Lookup Table [%d]:\n", i);
		for (j = 0; pImportLookupTable[j].u1.Ordinal != 0; j++) {
			if (pImportLookupTable[j].u1.Ordinal & ordinal_mask) {
				// reference by ordinal
				pOrdinal = (WORD*)((DWORD)&pImportLookupTable[j].u1.Ordinal + 2); // get low 2 bytes
				printf("#%d -> ordinal: %d\n", j, *pOrdinal);
			}
			else {
				// reference by name
				pName = (IMAGE_IMPORT_BY_NAME*)RVAToFOA((BYTE*)pImportLookupTable[j].u1.AddressOfData, fileBuffer);
				printf("#%d -> hint: %d, name: %s\n", j, pName->Hint, &pName->Name); // get name address
			}
		}
		printf("\n");
		
		// Import Address Table is same as Import Lookup Table before loading
		pImportAddressTable = (IMAGE_THUNK_DATA32*)RVAToFOA((BYTE*)pImportDirectory[i].FirstThunk, fileBuffer);
		printf("Import Address Table [%d]:\n", i);
		for (j = 0; pImportAddressTable[j].u1.Ordinal != 0; j++) {
			printf("#%d -> addr: %x\n", j, pImportAddressTable[j].u1.Ordinal);
		}
		printf("===========================\n");
		printf("\n");
	
		// do NOT forget to update table pointer
		pImportDirectoryTable++;
	}
}

STATUS PEParser(IN PMEMORYBASE filebase) {
    ...
    // Update import directory
	if (pDirectory[1].VirtualAddress != 0) {
		pImportDirectory = (IMAGE_IMPORT_DESCRIPTOR*)RVAToFOA((BYTE*)pDirectory[1].VirtualAddress, fileBuffer);
	}
    ...
}

void TEST_PrintImportDirectoryTable() {
	STATUS ret;
	// Initialize global pointers
	fileBuffer = nullptr;
	imageBuffer = nullptr;
	pDosHeader = nullptr;
	pFileHeader = nullptr;
	pOptionalHeader = nullptr;

	ret = PEReader("notepad.exe", &fileBuffer);
	ret = PEParser(fileBuffer);
	printHeaders();
	printImportDirectory();

	free(fileBuffer);
}
```

Notice that the assignment of pointers to import lookup table and import address table should be in the loop body of each import directory table.

## IAT

From notes above, we know that import address table is a part of import data section. Now we will discuss it from a designer why IAT is so important.

```cpp
#include <stdio.h>

#pragma comment (lib, "myDLL.lib")

extern "C" _declspec(dllimport) int __stdcall Plus(int x, int y);

int PlusBuiltin(int x, int y) {
	return x + y;
}

int main(int argc, char* argv[]) {
	
	printf("DLL Plus: %d\n", Plus(2, 3));
	printf("Builtin Plus: %d\n", PlusBuiltin(2, 3));

	return 0;
}
```

Dive into assembly language, there are differences in function calling between builtin function and imported function.

```c
// dll plus:
00401068 8B F4                mov         esi,esp
0040106A 6A 03                push        3
0040106C 6A 02                push        2
0040106E FF 15 AC A2 42 00    call        dword ptr [__imp__Plus@8 (0042a2ac)]
// balance check
00401074 3B F4                cmp         esi,esp
...

// the value of 0043a2ac in memory is 0A 10 00 10
1000100A E9 21 00 00 00       jmp         10001030
...
// notice that dll function is resident in high memory address
10001030 55                   push        ebp
10001031 8B EC                mov         ebp,esp
10001033 83 EC 40             sub         esp,40h
10001036 53                   push        ebx
10001037 56                   push        esi
10001038 57                   push        edi
10001039 8D 7D C0             lea         edi,[ebp-40h]
1000103C B9 10 00 00 00       mov         ecx,10h
10001041 B8 CC CC CC CC       mov         eax,0CCCCCCCCh
10001046 F3 AB                rep stos    dword ptr [edi]
10001048 8B 45 08             mov         eax,dword ptr [ebp+8]
1000104B 03 45 0C             add         eax,dword ptr [ebp+0Ch]
1000104E 5F                   pop         edi
1000104F 5E                   pop         esi
10001050 5B                   pop         ebx
10001051 8B E5                mov         esp,ebp
10001053 5D                   pop         ebp
...
```

```c
// builtin plus:
00401089 6A 03                push        3
0040108B 6A 02                push        2
0040108D E8 73 FF FF FF       call        @ILT+0(PlusBuiltin) (00401005)
00401092 83 C4 08             add         esp,8

// the value of 00401005 in memory is E9 16 00 00 which is calculated by hard code equation mentioned in previous notes
00401005 E9 16 00 00 00       jmp         PlusBuiltin (00401020)
... 
// the function body is in the memory scope of the executable file
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
00401038 8B 45 08             mov         eax,dword ptr [ebp+8]
0040103B 03 45 0C             add         eax,dword ptr [ebp+0Ch]
0040103E 5F                   pop         edi
0040103F 5E                   pop         esi
00401040 5B                   pop         ebx
00401041 8B E5                mov         esp,ebp
00401043 5D                   pop         ebp
00401044 C3                   ret
```

Therefore, `0042a2ac` serves as a box reserved for saving the real memory address of imported function. If we open the program above with a hex-notepad, we will find `0042a2ac` just save a meaningless value. After loading all dlls, the loader will fix the value of these addresses according to IAT, which saves the addresses that need to be fixed.

BTW, the BIG difference between IAT and base relocation table is that IAT is used to fix the address of imported function, while base relocation table is for updating its own pre-compiled function addresses since the file is not loaded at preferred image base.

Take an example, if pad.exe relies on three dlls, assuming dll1, dll2, dll3. And preferred `ImageBase` of dlls are `0x100000`. The diagram below describes how a loader works.

![How Loader Works](codehome/src/img/backward/DLLExample.png)

- Memory allocation for the Executable.
- Memory allocation for dll1. Image base is equal to `ImageBase`, thereby there is no need to fix function addresses within dll1, and the loader will update address in IAT for dll1.
- Memory allocation for dll2. Image base is not same with preferred `ImageBase`, thereby fix function addresses within dll2 according to base relocation of dll2, and the loader will update address in IAT for dll2. 
- Memory allocation for dll3. Operations is same as dll2.
- Fix memory addresses of the executable according to IAT.

## Bound Import

### Introduction

After discussing import directory, the other table which has something to do with import directory is bound import table.

See two import tables of different applications.

![Import Table of MyApp.exe](codehome/src/img/backward/myAppImportTable.png)

![Import Table of Notepad.exe](codehome/src/img/backward/notepadImportTable.png)

Notice that there are two main differences between import tables above:

- Time/Date Stamp: is set to 0 for MyApp.exe, while -1(`0xffffffff`) for notepad.exe.
- IAT: for MyApp.exe, each entry in IAT is a block of memory where the real function address will be written after loading dlls, while entries in IAT of notepad.exe are already bound to real function addresses before loading dlls.

That's significant distinction between import table and bound import table. **Bound Import Table**'s `Time/Date Stamp` is set to be `-1` and IAT has been set as "real function address". But why to bind address before loading?

PROS:

- Load program will get faster since we don't have to wait until all dlls have been loaded.

CONS:

- If the dll fails to occupy preferred image base, which means the addresses bound in IAT in advance is problematic, the IAT has to be updated according to real image base.
- If some functions of the dll are changed, which means the address of function will change, the IAT must be updated.

BTW: the loader checks the uniformity of addresses in IAT and dll by `Time/Date Stamp` of dll and image bound import descriptor, a structure which we will talk about in next part. When it is 0, it means the IAT will be bound after loading dlls. When it is -1, it means the IAT has been bound in advance. Then the loader will check if `Time/Date Stamp` of import descriptor is equal to that of dlls. If so, the bound addresses are okay, otherwise, the IAT has to be updated.

```c
// pseudo code for updating IAT in case 1: preferred image base has been occupied
...
PEReader("name.dll", &fileBuffer);
PEParser(fileBuffer);
preferredImageBase = pOptionalHeader->ImageBase;
free(fileBuffer);
fileBuffer = nullptr;

PEReader("name.exe", &fileBuffer);
PEParser(fileBuffer);
...
for (int i = 0; pImportAddressTable[i].u1.Ordinal != 0; i++) {
	// imageBase is the real image base where dll is located
	pImportAddressTable[i].u1.Ordinal += imageBase - preferredImageBase;
}
```

To sum up, the relationship between import directory and bound import table is that before the import directory fixes addresses in IAT for a dll, it will check in bound directory table if the dll is bound in advance and if the bound information is up-to-date by checking time/date stamp. 

### Structure

Image bound import table has structures as follows,

```c
typedef struct _IMAGE_BOUND_IMPORT_DESCRIPTOR {		
    DWORD   TimeDateStamp;		
    WORD    OffsetModuleName;		
    WORD    NumberOfModuleForwarderRefs;			
} IMAGE_BOUND_IMPORT_DESCRIPTOR, *PIMAGE_BOUND_IMPORT_DESCRIPTOR;

typedef struct _IMAGE_BOUND_FORWARDER_REF {		
    DWORD   TimeDateStamp;		
    WORD    OffsetModuleName;		
    WORD    Reserved;		
} IMAGE_BOUND_FORWARDER_REF, *PIMAGE_BOUND_FORWARDER_REF;		
```

Which looks like this:

![Structure of Bound Import Table](codehome/src/img/backward/StructureOfBoundTable.png)

There are two tricks when traversing such structure,

- `OffsetModuleName`: is a special "relative virtual address", which is the offset to the start address of the first descriptor, or say the file offset address of `VirtualAddress` in `DATA_DIRECTORY[11]`.
- `RVAToFOA`: in previous notes, we assumes that the data is in sections, however, in real condition, it can be in headers. Therefore we have to fix functions `RVAToFOA` and related functions.

```c
// for RVAToFOA() and VAToFOA(), add code segment as follows,
BYTE* RVAToFOA(IN BYTE* relativeVirtualAddress, IN BYTE* fileBase) {	
	...
	// if data is in header
	if (rva < p_section_header[0].VirtualAddress) {
		fileOffsetAddress = (BYTE*)((DWORD)fileBase + rva);
		return fileOffsetAddress; 
	}
	...
}

BYTE* VAToFOA(IN BYTE* relativeVirtualAddress, IN BYTE* fileBase) {
	...
	// if data is in header
	if (rva < p_section_header[0].VirtualAddress) {
		fileOffsetAddress = (BYTE*)((DWORD)fileBase + rva);
		return fileOffsetAddress; 
	}
	...
}

// for FOAToVA() and FOAToRVA(), add code segment as follows,
BYTE* FOAToRVA(IN BYTE* fileOffsetAddress, IN BYTE* fileBase) {
	...
	if (file_offset < p_section_header[0].PointerToRawData) {
		relativeVirtualAddress = (BYTE*)file_offset;
		return relativeVirtualAddress;
	}
	...
}

BYTE* FOAToVA(IN BYTE* fileOffsetAddress, IN BYTE* fileBase) {
	...
	if (file_offset < p_section_header[0].PointerToRawData) {
		virtualAddress = (BYTE*)((DWORD)pOptionalHeader->ImageBase + file_offset);
		return virtualAddress;
	}
	...
}
```

### Traverse Bound Import Table

```c
// PEParser.h
// printBoundImportDirectory:
//     The function will print bound import descriptors and forwarder references.
void printBoundImportDirectory();

// TEST_PrintBoundImportDirectory():
//     This function will test the print of bound import directory table.
void TEST_PrintBoundImportDirectory();
```

```c
void printBoundImportDirectory() {
	size_t i;
	WORD j;
	IMAGE_BOUND_FORWARDER_REF* pRef = nullptr;
	IMAGE_BOUND_IMPORT_DESCRIPTOR* pBoundDescriptor = pBoundImportTable;
	for (i = 0; pBoundDescriptor->TimeDateStamp != 0; i++) {
		printf("=============================\n");
		printf("Bound Import Descriptor [%d]\n", i);
		printf("Time/Date Stamp: %x\n", pBoundDescriptor->TimeDateStamp);
		printf("Module Name: %s\n", (char*)((DWORD)pBoundImportTable + pBoundDescriptor->OffsetModuleName));
		printf("NumberOfModuleForwarderRefs: %d\n", pBoundDescriptor->NumberOfModuleForwarderRefs);
		
		pRef = (IMAGE_BOUND_FORWARDER_REF*)((DWORD)pBoundDescriptor + sizeof(IMAGE_BOUND_IMPORT_DESCRIPTOR));
		for (j = 0; j < pBoundDescriptor->NumberOfModuleForwarderRefs; j++) {
			printf("\tRef [%d-%d]\n", i, j);
			printf("\tTime/Date Stamp: %x\n", pRef[i].TimeDateStamp);
			printf("\tModule Name: %s\n", (char*)((DWORD)pBoundImportTable + pRef[j].OffsetModuleName));
		}
		printf("============================\n");
		
		// update pointer: the length of a descriptor and n reference structure
		pBoundDescriptor = (IMAGE_BOUND_IMPORT_DESCRIPTOR*)(&pRef[j]);
	}
}

void TEST_PrintBoundImportDirectory() {
	STATUS ret;
	// Initialize global pointers
	fileBuffer = nullptr;
	imageBuffer = nullptr;
	pDosHeader = nullptr;
	pFileHeader = nullptr;
	pOptionalHeader = nullptr;

	ret = PEReader(FILE_IN, &fileBuffer);
	ret = PEParser(fileBuffer);
	printBoundImportDirectory();

	free(fileBuffer);
}
```

<EndMarkdown>