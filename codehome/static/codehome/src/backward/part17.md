# PE Seg.8

## Table of Contents
- [Loader](#loader)
- [Base Relocation Table](#baserelocationtable)
	- [Base Relocation Block](#baserelocationblock)
	- [C Program](#cprogram)
	- [Simulation](#simulation)
- [Move Tables](#movetables)
	- [Export Tables](#exporttables)
	- [Base Relocation Blocks](#baserelocationblocks)

<TableEndMark>

## Loader

In computer systems a **loader** is the part of an operating system that is responsible for loading programs and libraries. It is one of the essential stages in the process of starting a program, as it places programs into memory and prepares them for execution. Loading a program involves reading the contents of the executable file containing the program instructions into memory, and then carrying out other required preparatory tasks to prepare the executable for running. Once loading is complete, the operating system starts the program by passing control to the loaded program code.

All operating systems that support program loading have loaders, apart from highly specialized computer systems that only have a fixed set of specialized programs. Embedded systems typically do not have loaders, and instead, the code executes directly from ROM. In order to load the operating system itself, as part of booting, a specialized boot loader is used. In many operating systems, the loader resides permanently in memory, though some operating systems that support **virtual memory** may allow the loader to be located in a region of memory that is pageable.

In the case of operating systems that support virtual memory, the loader may not actually copy the contents of executable files into memory, but rather may simply declare to the virtual memory subsystem that there is a mapping between a region of memory allocated to contain the running program's code and the contents of the associated executable file. The virtual memory subsystem is then made aware that pages with that region of memory need to be filled on demand if and when program execution actually hits those areas of unfilled memory. This may mean parts of a program's code are not actually copied into memory until they are actually used, and unused code may never be loaded into memory at all.

Now let's see what virtual memory looks like,

![Virtual Memory](codehome/src/img/backward/win32Memory.png)

The loader will pad codes into different parts in priority order. In general, the executable is padded first according to its `ImageBase`, and then other codes like dynamic link library. 

- `ImageBase` conflict

Yet, a problem arises -- what if the address to be allocated of dll is occupied by previous codes? In other word, the `ImageBase` of different files conflicts with each other.

![Dynamic Link Library](codehome/src/img/backward/dllProblem.png)

However in the stage of compiling dynamic library, it is assumed that it will be placed in preferred `ImageBase`, and thereby compiles addresses of dynamic library program in a fixed form of `VirtualAddress`, which is `ImageBase(preferred) + RVA`. While in case of being put in a base address different from preferred image base, the problem appears.

- Fixed virtual address problem

To be specific, imagine a scenario that we define a function to print the value of x, and compile it as a dynamic link library. Then we get assembly code as follows,

```c
00401D58 A1 44 CA 42 00       mov         eax,[x (0042ca44)]
00401D5D 50                   push        eax			
00401D5E 68 EC 91 42 00       push        offset string "%d\n" (004291ec)			
00401D63 E8 28 62 00 00       call        printf (00407f90)			
```

Notice that address above is virtual address, which is problematic since `virtual address = dll->ImageBase + relative virtual address` as we known from previous notes. Yet when a dll is loaded into memory, its `ImageBase` could be changed by loader for the address is occupied, thereby virtual address changed. 

For example, say `dll->ImageBase = 0x00400000` and `rva = 0x2ca44`. We compile it as a dynamic library, then address of `x` will be set as `0x0042ca44`, which is proper in current image. However if an executable uses the dll and compile it into a image whose address of `0x00400000` is occupied, the loader change its image base to `0x01000000`. Now the proper address should be `0x0102ca44`, not `0x0042ca44`. The problem is that virtual address has been fixed by `00401D58 A1 44 CA 42 00`, then it will go to wrong place when code is executed.

How to fixed problems above? The answer is **Base Relocation Table**. The primary task of it is to tell loader that which addresses need to be modified -- fix addresses WITHIN dll or the executable when it is not placed in preferred image base. That's a biggest difference from IAT.

## Base Relocation Table

The base relocation table (in the `.reloc` section) contains entries for all base relocations in the image. The Base Relocation Table field in the optional header data directories gives the number of bytes in the base relocation table.

The loader is not required to process base relocations that are resolved by the linker, unless the load image cannot be loaded at the image base that is specified in the PE header.

### Base Relocation Block

Each base relocation block starts with the following structure:

```c
typedef struct _IMAGE_BASE_RELOCATION {				
    DWORD   VirtualAddress;				
    DWORD   SizeOfBlock;				
} IMAGE_BASE_RELOCATION;
```				

| Offset | Size | Field | Description |
| :---: | :---: | :---: | :---: |
| 0 | 4 | Page RVA | The image base plus the page RVA is added to each offset to create the VA where the base relocation must be applied.
| 4 | 4 | Block Size | The total number of bytes in the base relocation block, including the Page RVA and Block Size fields and the Type/Offset fields that follow. |

The Block Size field is then followed by any number of Type or Offset field entries. Each entry is a WORD (2 bytes) and has the following structure:

| Offset | Size | Field | Description |
| :---: | :---: | :---: | :---: |
| 0 | 4 bits | Type | Stored in the high 4 bits of the WORD, a value that indicates the type of base relocation to be applied. For more information |
| 0 | 12 bits | Offset | Stored in the remaining 12 bits of the WORD, an offset from the starting address that was specified in the Page RVA field for the block. This offset specifies where the base relocation is to be applied. | 

To apply a base relocation, the difference is calculated between the preferred base address and the base where the image is actually loaded. If the image is loaded at its preferred base, the difference is zero and thus the base relocations do not have to be applied.

![Block Structure](codehome/src/img/backward/BaseRelocationBlock.png)

- Entry of Relocation Block: why low 12 bits? One block only record data to be modified in the size of one page of memory. since page size of memory is `0x1000`, i.e. 2^12, 12-bit wide data is enough to record offset of a page, ranging from `0` to `2^12 - 1`.

![Page Size](codehome/src/img/backward/PageSize.png)

- Base Relocation Types: is recorded by high 4-bit data.

| Constant | Value | Description |
| IMAGE_REL_BASED_ABSOLUTE | 0000b | The base relocation is skipped. This type can be used to pad a block for alignment. |
| IMAGE_REL_BASED_HIGHLOW | 0011b | The base relocation applies all 32 bits of the difference to the 32-bit field at offset. Need to be modified. |

- Virtual Address: the base of the block. Virtual address of data that need to be modified is `Virtual Address + low-12-bit data`.
- SizeOfBlock: the size of the block. `# of entry = (SizeOfBlock - 8) / 2`.

### C Program

Now we will list Base Relocation Table in C.

```c
// Global.h

#define TRUE 1
#define FALSE 0

///////////////////////////////
// Base Relocation Directory

typedef struct image_base_relocation {				
    DWORD   VirtualAddress;				
    DWORD   SizeOfBlock;				
} IMAGE_BASE_RELOCATION;
IMAGE_BASE_RELOCATION* pBaseRelocationBlock;

///////////////////////////////
```

```c
// PEParser.h
// printBaseRelocationDirectory:
//     The function will print each base relocation block.
void printBaseRelocationDirectory();
```

```c
// PEParser.c
void printBaseRelocationDirectory() {
	size_t numOfBlocks = 0;
	size_t numOfEntry = 0;
	size_t i;
	IMAGE_BASE_RELOCATION* pBlock = pBaseRelocationBlock;
	WORD* pEntry = nullptr;
	WORD entry = 0;
	DWORD rva = 0;

	while (TRUE) {
		// TODO: check End Flag
		if ((pBlock->VirtualAddress == 0) && (pBlock->SizeOfBlock == 0)) {
			break;
		}

		printf("Block %d:\n", numOfBlocks);
		printf("VirtualAddress: %x\n", pBlock->VirtualAddress);
		printf("SizeOfBlock: %x\n", pBlock->SizeOfBlock);

		numOfEntry = (pBlock->SizeOfBlock - 8) / 2;
		// trick here to jump over virtualaddress and size of block
		pEntry = (WORD*)(&pBlock[1].VirtualAddress);
		for (i = 0; i < numOfEntry; i++) {
			entry = pEntry[i];
			// 0000111111111111b = 0x0FFF
			rva = entry & 0x0FFF;
			printf("Entry %d: %x\n", i, rva + pBlock->VirtualAddress);
		}
		
		// TODO: update arguments
		numOfBlocks++;
		pBlock = (IMAGE_BASE_RELOCATION*)((DWORD)pBlock + pBlock->SizeOfBlock);
	}
}


STATUS PEParser(IN PMEMORYBASE filebase) {
    ...
    // Update base relocation directory, the sixth table in data directory.
	pBaseRelocationBlock = (IMAGE_BASE_RELOCATION*)VAToFOA((BYTE*)(pDirectory[5].VirtualAddress + pOptionalHeader->ImageBase), fileBuffer);
    ...
}
	
```

### Simulation

Now we are going to simulate how loader use base relocation table to fix address of dll file. 

Assuming that the physical image base is `0x20000000` rather than preferred image base `0x10000000` in general, then we have to fix those absolute addresses according to base relocation table.

So what we are going to do is to change preferred image base to physical image base to fix image base conflict, the behavior somewhat similar to what loader does. Yet actually loader does not change the `ImageBase`, but use physical image base according to memory allocation. Despite of that those absolute addresses compiled when generating dynamic library have to be updated.

For each absolute address, `new_addr = addr + delta(ImageBase) = addr + (NewImageBase - pOptionalHeader->ImageBase)`, since absolute address `addr = rva + pOptionalHeader->ImageBase`.

```c
// Tools.h
// UpdateAddrWithBaseRelocationTable:
//     The function will change ImageBase and update entries of each base relocation block.
// @buffer: the buffer to be operated.
// @newImageBase: new image base.
STATUS UpdateAddrWithBaseRelocationTable(IN PMEMORYBASE buffer, DWORD newImageBase);

// TEST_UpdateAddrWithBaseRelocationTable():
//     This function will test the validation of void UpdateAddrWithBaseRelocationTable.
void TEST_UpdateAddrWithBaseRelocationTable();
```

```c
STATUS UpdateAddrWithBaseRelocationTable(IN PMEMORYBASE buffer, DWORD newImageBase) {
	size_t i;
	IMAGE_BASE_RELOCATION* pBlock = pBaseRelocationBlock;
	DWORD numOfEntries = 0;
	WORD* pEntry = nullptr;
	WORD entry = 0;
	WORD flag = 0;
	DWORD rva = 0;
	BYTE* foa = nullptr;
	DWORD* addr = nullptr;
	DWORD new_addr = 0;

	while (TRUE) {
		if ((pBlock->VirtualAddress == 0) && (pBlock->SizeOfBlock == 0)) {
			break;
		}
		
		// TODO: update entry of each block
		numOfEntries = (pBlock->SizeOfBlock - 8) / 2;
		pEntry = (WORD*)((DWORD)pBlock + IMAGE_SIZEOF_BASE_RELOCATION);
		for (i = 0; i < numOfEntries; i++) {
			entry = pEntry[i];
			flag = entry & 0xF000;
			rva = (entry & 0x0FFF) + pBlock->VirtualAddress;
			if (flag == 0x3000) {
				// update the address the entry points to 
				foa = RVAToFOA((BYTE*)rva, buffer);
				addr = (DWORD*)foa;
				new_addr = *addr + (newImageBase - pOptionalHeader->ImageBase);
				memcpy(foa, &new_addr, sizeof(DWORD));
			}
		}

		// go to next block
		pBlock = (IMAGE_BASE_RELOCATION*)((DWORD)pBlock + pBlock->SizeOfBlock);
	}

	pOptionalHeader->ImageBase = newImageBase;

	return 0;
}

void TEST_UpdateAddrWithBaseRelocationTable() {
	STATUS ret;
	// Initialize global pointers
	fileBuffer = nullptr;
	imageBuffer = nullptr;
	pDosHeader = nullptr;
	pFileHeader = nullptr;
	pOptionalHeader = nullptr;

	ret = PEReader("NONameDLL.dll", &fileBuffer);
	ret = PEParser(fileBuffer);
	printHeaders();
	printBaseRelocationDirectory();

	ret = UpdateAddrWithBaseRelocationTable(fileBuffer, 0x11000000);
	printBaseRelocationDirectory();

	free(fileBuffer);
}
```



## Move Tables

Why to move tables? If we want to encrypt our program, we have to keep some information unencrypted that loader needs when loading file into memory image, such as headers, tables and so on. Yet some tables are mixed into sections with data as follows,

![Mixed Structure](codehome/src/img/backward/MixedStructure.png)

Therefore the proper process of encryption is shown below,

![Process of Encryption](codehome/src/img/backward/Encryption.png)

So moving tables is a critical operation for encryption.

### Export Tables

The basic steps of moving export table are:

- Add a new section in DLL.
- Copy Address Table to the new section, notice `length = sizeof(func_address) * NumberOfFunctions`.
- Copy Name Ordinal Table to the new section, notice `length = sizeof(ordinal) * NumberOfNames`.
- Copy Name Pointer Table to the new section, notice `length = sizeof(name_address) * NumberOfNames`.
- Copy all public function names to the new section. Warning: we cannot do it by dynamic memory allocation since we have to keep it in a safe place, rather than heap, to ensure function names will not be encrypted. *Do NOT forget to update address of new name pointer table*.
- Copy Image Export Directory to the new section, and update the address of three tables.
- Modify address of Image Export Directory in Image Data Directory. 

```c
// Global.h
// Add two auxiliary functions: RVAToFOA() and FOAToRVA()
// which is similar to VA version
// RVAToFOA:
//     The function will translate relative virtual address to file offset address of a given file buffer.
// @relativeVirtualAddress: relative virtual address of data in image buffer.
// @fileBase: the base address of file buffer.
// RVA means relative virtual address in image buffer
// FOA means absolute file offset address in file buffer
BYTE* RVAToFOA(IN BYTE* relativeVirtualAddress, IN BYTE* fileBase);

// FOAToRVA
//     The function will translate file offset address to relative virtual address of a given image buffer.
// @fileOffsetAddress: file offset address of data in file buffer(+fileBuffer).
// @fileBase: the base address of file buffer.
// RVA means relative virtual address in image buffer
// FOA means absolute file offset address in file buffer
BYTE* FOAToRVA(IN BYTE* fileOffsetAddress, IN BYTE* fileBase);
```

```c
// Global.c
BYTE* RVAToFOA(IN BYTE* relativeVirtualAddress, IN BYTE* fileBase) {
	size_t i = 0;
	DWORD section_num = -1;
	DWORD rva = (DWORD)relativeVirtualAddress;
	BYTE* fileOffsetAddress = nullptr;
	size_t number_of_sections = (size_t)pFileHeader->NumberOfSections;
	DWORD offset = 0;

	// check which section it belongs to
	for (; i < number_of_sections; i++) {
		if (isInSection(rva, p_section_header[i].VirtualAddress, p_section_header[i].VirtualAddress + p_section_header[i].SizeOfRawData)) {
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
	fileOffsetAddress = (BYTE*)((DWORD)fileBase + p_section_header[section_num].PointerToRawData + offset);

	return fileOffsetAddress;
}

BYTE* FOAToRVA(IN BYTE* fileOffsetAddress, IN BYTE* fileBase) {
	size_t i;
	DWORD section_num = -1;
	DWORD file_offset = (DWORD)fileOffsetAddress - (DWORD)fileBase;
	BYTE* relativeVirtualAddress = nullptr;
		
	size_t number_of_sections = (size_t)pFileHeader->NumberOfSections;
	DWORD offset = 0;

	// check which section it belongs to
	for (i = 0; i < number_of_sections; i++) {
		if (isInSection(file_offset, p_section_header[i].PointerToRawData, p_section_header[i].PointerToRawData + p_section_header[i].SizeOfRawData)) {
			section_num = i;
			break;
		}
	}

	// error checking
	if (section_num == -1) {
		printf("Error: Data is not in legal range of any section.\n");
		exit(-1);
	}
	
	// calculate offset to the begin of section in file buffer
	offset = file_offset - p_section_header[section_num].PointerToRawData;

	// get virtual address
	relativeVirtualAddress = (BYTE*)((DWORD)p_section_header[section_num].VirtualAddress + offset);

	return relativeVirtualAddress;
}
```

```c
// Tools.h
// MoveExportDirectoryToNewAddress:
//     The function will move export directory from .edata to given address.
// @location: the location where export directory is going to be put.
// @buffer: the buffer that is going to be operated.
// @Return: the total size of memory has been taken in byte.
STATUS MoveExportDirectoryToNewAddress(IN BYTE* location, IN PMEMORYBASE buffer);

// TEST_MoveExportDirectoryToNewAddress:
//     This function will test the validation of MoveExportDirectoryToNewAddress.
void TEST_MoveExportDirectoryToNewAddress();
```

```c
// Tools.c
STATUS MoveExportDirectoryToNewAddress(IN BYTE* location, IN PMEMORYBASE buffer) {
	DWORD totalSize = 0;
	size_t i;
	BYTE* ptrName; // file offset address of original public name 
	BYTE* newNameAddr; // pointer to new public name in new section
	NAME_POINTER_TABLE* newNamePointerTable = nullptr;
	size_t length = 0;
	BYTE* begin = location; // track the address where to copy table

	// TODO: copy address table
	length = pExportDirectory->NumberOfFunctions * sizeof(DWORD);
	memcpy(begin, pAddressTable, length);
	pAddressTable = (EXPORT_ADDRESS_TABLE*)begin;
	
	// TODO: copy name ordinal table
	begin = (BYTE*)((DWORD)begin + length);
	length = pExportDirectory->NumberOfNames * sizeof(WORD);
	memcpy(begin, pNameOrdinalTable, length);
	pNameOrdinalTable = (NAME_ORDINAL_TABLE*)begin;
	
	// TODO: copy name pointer table
	length = pExportDirectory->NumberOfNames * sizeof(DWORD);
	begin = (BYTE*)((DWORD)begin + length);
	memcpy(begin, pNamePointerTable, length);
	newNamePointerTable = (NAME_POINTER_TABLE*)begin;
	
	// TODO: copy all public name and update pointers in new memory
	newNameAddr = (BYTE*)((DWORD)begin + length); 
	for (i = 0; i < pExportDirectory->NumberOfNames; i++) {
		ptrName = (BYTE*)RVAToFOA((BYTE*)pNamePointerTable[i].NameVirtualAddress, buffer);
		length = strlen(ptrName);
		// +1 for '\0'
		memcpy(newNameAddr, ptrName, length + 1);
		// update address
		newNamePointerTable[i].NameVirtualAddress = (DWORD)FOAToRVA(newNameAddr, buffer);

		// update newNameAddr
		newNameAddr = (BYTE*)((DWORD)newNameAddr + length + 1);
	}
	pNamePointerTable = newNamePointerTable;

	// TODO: copy image export directory
	// TIP: after looping above, newNameAddr will point to the end of address of the last public name
	begin = newNameAddr;
	memcpy(begin, pExportDirectory, IMAGE_SIZEOF_EXPORT_DIRECTORY);
	pExportDirectory = (IMAGE_EXPORT_DIRECTORY*)begin;
	// update table address
	pExportDirectory->AddressOfFunctions = (DWORD)FOAToRVA((BYTE*)pAddressTable, buffer);
	pExportDirectory->AddressOfNameOrdinals = (DWORD)FOAToRVA((BYTE*)pNameOrdinalTable, buffer);
	pExportDirectory->AddressOfNames = (DWORD)FOAToRVA((BYTE*)pNamePointerTable, buffer);

	// TODO: update address of export directory in image data directory
	pDirectory[0].VirtualAddress = (DWORD)FOAToRVA((BYTE*)pExportDirectory, buffer);

	totalSize = (DWORD)begin - (DWORD)location +  IMAGE_SIZEOF_EXPORT_DIRECTORY;

	return totalSize;
}

// the function works with the help of AddSectionToBuffer
void TEST_MoveExportDirectoryToNewAddress() {
	STATUS ret;
	PMEMORYBASE newFileBuffer = nullptr;
	IMAGE_SECTION_HEADER* newSection;
	char name[SIZEOF_SECTION_NAME] = { 0x2e, 'e', 'd', 'a',
					't', 'a'};
	BYTE* location = nullptr;
	
	// Initialize global pointers
	fileBuffer = nullptr;
	imageBuffer = nullptr;
	pDosHeader = nullptr;
	pFileHeader = nullptr;
	pOptionalHeader = nullptr;

	ret = PEReader("NONameDLL.dll", &fileBuffer);
	ret = PEParser(fileBuffer);
	printHeaders();
	printExportDirectory();
	
	// prepare a new section
	newSection = (IMAGE_SECTION_HEADER*)malloc(sizeof(IMAGE_SECTION_HEADER));
	memset(newSection, 0, sizeof(IMAGE_SECTION_HEADER));
	memcpy(&newSection->Name, name, SIZEOF_SECTION_NAME);
	newSection->Misc.PhysicalAddress = 0x00001000;
	
	ret = AddSectionToBuffer(fileBuffer, newSection, &newFileBuffer);
	// relay to fileBuffer;
	free(fileBuffer);
	fileBuffer = newFileBuffer;
	newFileBuffer = nullptr;

	ret = PEParser(fileBuffer);
	location = (BYTE*)((DWORD)fileBuffer + p_section_header[pFileHeader->NumberOfSections - 1].PointerToRawData);
	ret = MoveExportDirectoryToNewAddress(location, fileBuffer);
	
	printHeaders();
	printExportDirectory();

	ret = SaveBufferAsFile("MoveExportDirectory.dll", fileBuffer);
	free(fileBuffer);
}
```

### Base Relocation Blocks

Now let's move base relocation blocks to the new section. The basic steps are as follows:

- Move base relocation blocks to the given location. The entries within each block does NOT need to be fixed when being moved since the address of code that these entries point to does not changed.
- Modify the virtual address of base relocation table in image data directory.

```c
// Tools.h
// MoveBaseRelocationTableToNewAddress:
//     The function will move base relocation table from .rdata to a given address.
// @location: the location where to put base relocation table.
// @buffer: the buffer to be operated.
// @Return: the total size of moved elements in byte.
STATUS MoveBaseRelocationTableToNewAddress(IN BYTE* location, IN PMEMORYBASE buffer);

// TEST_MoveBaseRelocationTableToNewAddress:
//     This function will test the validation of MoveBaseRelocationTableToNewAddress.
void TEST_MoveBaseRelocationTableToNewAddress();
```

```c
// Tools.c
STATUS MoveBaseRelocationTableToNewAddress(IN BYTE* location, IN PMEMORYBASE buffer) {
	BYTE* begin = location;
	IMAGE_BASE_RELOCATION* pBlock = pBaseRelocationBlock;
	DWORD totalSize = 0;

	while (TRUE) {
		// TODO: check End Flag
		if ((pBlock->VirtualAddress == 0) && (pBlock->SizeOfBlock == 0)) {
			// do NOT forget copy End Flag when jump out
			memcpy(begin, pBlock, IMAGE_SIZEOF_BASE_RELOCATION);
			break;
		}
		
		// TODO: copy block
		memcpy(begin, pBlock, pBlock->SizeOfBlock);

		begin = (BYTE*)((DWORD)begin + pBlock->SizeOfBlock);
		pBlock = (IMAGE_BASE_RELOCATION*)((DWORD)pBlock + pBlock->SizeOfBlock);
	}

	// TODO: update address of base relocation table in image data directory
	pDirectory[5].VirtualAddress = (DWORD)FOAToRVA((BYTE*)location, buffer);
	
	totalSize = (DWORD)begin - (DWORD)location + IMAGE_SIZEOF_BASE_RELOCATION;

	return totalSize;
}

void TEST_MoveBaseRelocationTableToNewAddress() {
	STATUS ret;
	PMEMORYBASE newFileBuffer = nullptr;
	IMAGE_SECTION_HEADER* newSection;
	char name[SIZEOF_SECTION_NAME] = { 0x2e, 'e', 'd', 'a',
					't', 'a'};
	BYTE* location = nullptr;
	
	// Initialize global pointers
	fileBuffer = nullptr;
	imageBuffer = nullptr;
	pDosHeader = nullptr;
	pFileHeader = nullptr;
	pOptionalHeader = nullptr;

	ret = PEReader("NONameDLL.dll", &fileBuffer);
	ret = PEParser(fileBuffer);
	printHeaders();
	printBaseRelocationDirectory();

	// TODO: prepare a new section
	newSection = (IMAGE_SECTION_HEADER*)malloc(sizeof(IMAGE_SECTION_HEADER));
	memset(newSection, 0, sizeof(IMAGE_SECTION_HEADER));
	memcpy(&newSection->Name, name, SIZEOF_SECTION_NAME);
	// Notice that we have to allocate a enough space for saving base relocation table
	newSection->Misc.PhysicalAddress = 0x00002000;
	newSection->Characteristics = 0x42000040;
	
	ret = AddSectionToBuffer(fileBuffer, newSection, &newFileBuffer);
	// relay to fileBuffer;
	free(fileBuffer);
	fileBuffer = newFileBuffer;
	newFileBuffer = nullptr;

	ret = PEParser(fileBuffer);
	location = (BYTE*)((DWORD)fileBuffer + p_section_header[pFileHeader->NumberOfSections - 1].PointerToRawData);
	ret = MoveBaseRelocationTableToNewAddress(location, fileBuffer);
	
	printHeaders();
	printBaseRelocationDirectory();
	// output: 0x133c, therefore the size of the new section should be greater than align(0x133c, 0x1000)
	printf("The total size of base relocation table: %x\n", ret);

	ret = SaveBufferAsFile("MoveRelocationTable.dll", fileBuffer);

	free(fileBuffer);
}
```

<EndMarkdown>