# PE Seg.4 - Shell Code

## Table of Contents
- [Add to Code Section](#addtocodesection)
	- [NotePad](#notepad)
	- [C Program](#cprogram)
- [Add a New Section](#addanewsection)
	- [Prerequisite](#prerequisite)
	- [C](#c)
	- [Add to a New Section](#addtoanewsection)

<TableEndMark>

## Add to Code Section

Assuming that we are going to add `MessageBox` to code section of a PE file. How could we achieve that?

- Find the image address of `MessageBox`, 0x77D5050B on my machine.

![Address of MessageBox](codehome/src/img/backward/MessageBox.png)

- Use `jmp` and `call` instruction to change work flow of a program.
- Modify `AddressOfEntryPoint(OEP)` of the program.

```bash
# Add shell code
-- Entry Point --| - - - - X - - - -|-- Original Code -->
                 |                  |
            call |                  | jmp
                 |                  |
                 |->- Shell Code ->-|
```

Assembly instruction to achieve that is as follows, assuming the shell code is a MessageBox function. Notice that MessageBox is an inner-balanced function.

```c
// MessageBox(0, 0, 0, 0);
push 0
push 0
push 0
push 0
call addr[MessageBox]
jmp addr[Original Code]
```

##### Call and Jmp

Before we go to the second step, we have to dig out the hard code of `Call` and `Jmp`.

```c
void func() {

}

int main(int argc, char* argv[]) {

    func();

    return 0;
}

// caller:
7:        func();
00401068 E8 98 FF FF FF       call        @ILT+0(func) (00401005)
00401005 E9 76 C4 00 00       jmp         func (0040d480)
```

Notice that `E8 + addr[4 bytes]` is the hard codes of `call` and `E9 + addr` for `jmp`. However, `addr` is not the memory address of function(`0x00401005`). `addr` in hard code is defined by following equation,

```bash
# how to calculate jump address
memory address = addr[next instruction] + X;
# put X to left hand side
X = memory address - addr[next instruction];

# however, 1 byte (E8/E9) + 4 bytes address = 5 bytes
addr[next instruction] = addr[current instruction] + 5
# therefore, we get another equation
X = memory address - addr[current instruction] - 5
```

IMPORTANT: all memory addresses(function address and code address) here are the address of memory image rather than of file. Thereby, if we program to achieve insert code, we have to transfer file offset address to relative virtual address for code address.

##### MessageBox

Now we have to get hard code of arguments of `MessageBox`.

```c
#include <windows.h>

int main(int argc, char* argv[]) {
    MessageBox(0, 0, 0, 0);

    return 0;
}

// caller:
4:        MessageBox(0, 0, 0, 0);
00401028 8B F4                mov         esi,esp
0040102A 6A 00                push        0
0040102C 6A 00                push        0
0040102E 6A 00                push        0
00401030 6A 00                push        0
00401032 FF 15 AC A2 42 00    call        dword ptr [__imp__MessageBoxA@16 (0042a2ac)]
00401038 3B F4                cmp         esi,esp
0040103A E8 31 00 00 00       call        __chkesp (00401070)
```

Therefore, the complete hard code is `6A 00 6A 00 6A 00 6A 00 E8 XX XX XX XX E9 XX XX XX XX`. We are going to insert the hard code to code section(.text).

![Insert to Code Section](codehome/src/img/backward/insertToCodeSection.png)

BTW, we have to check if the size of memory available is large enough to write these hard codes, `available size = SizeOfRawData - VirtualSize`. 

##### Modify OEP

At last we are going to modify `AddressOfEntryPoint`. IMPORTANT, `AddressOfEntryPoint` saves offset rather than absolute address.

### NotePad

Now let's place it into practice, we are going to add `MessageBox` to `notepad.exe`.

##### Header Elements

```c
// some elements to use
OptionalHeader {
    AddressOfEntryPoint: 739d
    ImageBase: 1000000
    SectionAlignment: 1000
    FileAlignment: 200
    SizeOfHeaders: 400
}

// .text
SectionHeader[0] {
    Name: .text
    Misc: 7748
    VirtualAddress: 1000
    SizeOfRawData: 7800
    PointerToRawData: 400  // notice equal to SizeOfHeaders
    Characteristics: 60000020
}

SectionHeader[1] {
    Name: .data
    Misc: 1ba8
    VirtualAddress: 9000 // VirtualAddress[1] = VirtualAddress[0] + SectionAlignment(SizeOfRawData[0])
    SizeOfRawData: 800
    PointerToRawData: 7c00 // PointerToRawData[1] = PointerToRawData[0] + SizeOfRawData[0]
    Characteristics: c0000040
}

AddressOfFunction(MessageBox): 0x77D5050B
EntryPoint = AddressOfEntryPoint + ImageBase = 739d + 1000000 = 100739d
```

Therefore, we know that `Available Memory Size = SizeOfRawData[0] - Misc[0] = 7800 - 7748 = 52 bytes`, and `The End Of Code[0] = PointerToRawData[0] + Misc[0] = 400 + 7748 = 7B48`.

![End of Code in Section 0](codehome/src/img/backward/endOfCode.png)

##### FOA to RVA

Now we are going to transfer file offset address(FOA) to relative virtual address(RVA).

- Calculate offset to section[0], `offset = 0x007B58 - PointerToRawData[0] = 0x007758`.
- Calculate relative virtual address, `rva = offset + ImageBase + VirtualAddress[0] = 0x007758 + 0x1000000 + 0x1000 = 0x1008758`
- Calculate hard code address, `X = AddressOfFunction(MessageBox) - rva - 5 = 0x77D5050B - 0x1008758 - 5 = 0x76D47DAE`.

Therefore, the hard code address of `call` is `AE 7D D4 76`.

Then let's calculate jmp addr.

- Calculate offset to section[0], `offset = 0x007B5D - PointerToRawData[0] = 0x00775D`.
- Calculate relative virtual address, `rva = offset + ImageBase + VirtualAddress[0] = 0x00775D + 0x1000000+ 0x1000 = 0x100875D`
- Calculate hard code of address, `X = EntryPoint - rva - 5 = 0x100739D - 0x100875D - 5 = 0xFFFFEC3B`

Therefore, the hard code address of `jmp` is `3B EC FF FF`.

At last, we will change entry of point. Entry of point should be the address of the beginning of shell code, `0x007B50` in file. Also, translate to relative virtual address.

- Calculate offset to section[0], `offset = 0x007B50 - PointerToRawData[0] = 0x007750`.
- Calculate relative virtual address, `rva = offset + ImageBase + VirtualAddress[0] = 0x007750 + 0x1000000 + 0x1000 = 0x1008750`.
- However, AddressOfEntryPoint does NOT include ImageBase, thereby `AddressOfEntryPoint = rva - ImageBase = 0x8750`.

Therefore, AddressOfEntryPoint is `50 87 00 00`.

To sum up, the hard code we are going to insert is `6A 00 6A 00 6A 00 6A 00 E8 AE 7D D4 76 E9 3B EC FF FF`, and change AddressOfEntryPoint to `50 87 00 00`.

### C Program

We could achieve it with C program automatically. Also we need a helper function `FOAtoVA()`.

```c
// Tools.h
// FOAToVA
//     The function will translate file offset address to virtual address of a given image buffer.
// @fileOffsetAddress: file offset address of data in file buffer(+fileBuffer).
// @imageBuffer: the base address of image buffer.
// VA means absolute virtual address in image buffer
// FOA means absolute file offset address in file buffer
BYTE* FOAToVA(IN BYTE* fileOffsetAddress, IN BYTE* imageBuffer);

// TEST_AddShellCodeToCodeSection:
//     This function will add shell code to code section.
void TEST_AddShellCodeToCodeSection();
```

```c
BYTE* FOAToVA(IN BYTE* fileOffsetAddress, IN BYTE* fileBase) {
	size_t i;
	DWORD section_num = -1;
	DWORD file_offset = (DWORD)fileOffsetAddress - (DWORD)fileBase;
	BYTE* virtualAddress = nullptr;
		
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
	virtualAddress = (BYTE*)((DWORD)pOptionalHeader->ImageBase + p_section_header[section_num].VirtualAddress + offset);

	return virtualAddress;
}
```

```c
void TEST_AddShellCodeToCodeSection() {
	STATUS ret;
	DWORD offset_to_end_of_code = 10;
	BYTE SHELL_CODE[] = { 0x6A, 0x00, 0x6A, 0x00, 0x6A, 0x00, 0x6A, 0x00,
						  0xE8, 0x00, 0x00, 0x00, 0x00, 0xE9, 0x00, 0x00,
						  0x00, 0x00 };
	// this value is different from machine to machine
	BYTE* AddrOfMessageBox = (BYTE*)0x77D5050B;
	DWORD size_of_available_space = 0;
	// code section number
	DWORD section_num = 0;
	// where to insert
	BYTE* startPoint = nullptr;
	BYTE* virtualAddress = nullptr;
	BYTE* addr_in_hardcode = nullptr;
	BYTE* EntryPoint;
	
	// initialize global pointers
	fileBuffer = nullptr;
	imageBuffer = nullptr;
	pDosHeader = nullptr;
	pFileHeader = nullptr;
	pOptionalHeader = nullptr;

	ret = PEReader("notepad.exe", &fileBuffer);
	ret = PEParser(fileBuffer);
	printHeaders();

	// TODO: check if space is available and enough to write shell code
	size_of_available_space = p_section_header[section_num].SizeOfRawData - p_section_header[section_num].Misc.VirtualSize;
	if (size_of_available_space <= sizeof(SHELL_CODE)) {
		printf("ERROR: memory space is not enough.\n");
		exit(-1);
	}
	
	// TODO: copy shell code to code section
	// 6A 00 6A 00 6A 00 6A 00 E8 00 00 00 00 E9 00 00 00 00 
	startPoint = (BYTE*)((DWORD)fileBuffer + p_section_header[section_num].PointerToRawData + p_section_header[section_num].Misc.VirtualSize + offset_to_end_of_code);
	memcpy(startPoint, SHELL_CODE, sizeof(SHELL_CODE));

	
	// TODO: update hard code address
	// copy hard code of call address to memory space next to E8
	// 6A 00 6A 00 6A 00 6A 00 E8 AC 7D D4 76 E9 00 00 00 00 
	virtualAddress = FOAToVA(startPoint + 8, (BYTE*)pOptionalHeader->ImageBase);
	// transform with hard code equation
	addr_in_hardcode = (BYTE*)((DWORD)AddrOfMessageBox - (DWORD)virtualAddress - 5);
	memcpy(startPoint + 9, &addr_in_hardcode, sizeof(DWORD));

	if (DEBUG) {
		printf("Tools.TEST_AddShellCodeToCodeSection:\n");
		printf("start point: %x\n", startPoint);
		printf("virtual address of call: %x, hard code: %x\n", virtualAddress, addr_in_hardcode);
	}

	// copy hard code of jmp address to memory space next to E9
	// 6A 00 6A 00 6A 00 6A 00 E8 AC 7D D4 76 E9 39 EC FF FF 
	EntryPoint = (BYTE*)((DWORD)pOptionalHeader->ImageBase + (DWORD)pOptionalHeader->AddressOfEntryPoint);
	virtualAddress = FOAToVA(startPoint + 13, (BYTE*)pOptionalHeader->ImageBase);
	// transform with hard code equation
	addr_in_hardcode = (BYTE*)((DWORD)EntryPoint - (DWORD)virtualAddress - 5);
	memcpy(startPoint + 14, &addr_in_hardcode, sizeof(DWORD));

	if (DEBUG) {
		printf("virtual address of jmp: %x, hard code: %x\n", virtualAddress, addr_in_hardcode);
	}

	// modify AddressOfEntryPoint to start point
	virtualAddress = FOAToVA(startPoint, (BYTE*)pOptionalHeader->ImageBase);
	// minus ImageBase
	virtualAddress = (BYTE*)((DWORD)virtualAddress - pOptionalHeader->ImageBase);
	memcpy(&pOptionalHeader->AddressOfEntryPoint, &virtualAddress, sizeof(DWORD));

	if (DEBUG) {
		printf("virtual address of entry point: %x\n", virtualAddress);
	}

	ret = SaveBufferAsFile("msgBoxPad.exe", fileBuffer);

	free(fileBuffer);
}
```

## Add a New Section

Surprise! However, there is a shortcoming to inject shell code to an existed code section since it is highly likely that there is no enough memory space to write shell code.

Then there is a plan B - add a new section and place shell code there.

### Prerequisite

There are two prerequisites for doing that:

- if there is enough memory space for add two section headers in section table. (why two? we will explain it later)
- figure out what members we should change in order to ensure the program is executed properly.

##### Memory Size

In general, the member `SizeOfHeaders` is immune to change since it will change the address of following code when it is changed.

![Diagram of SizeOfHeaders](codehome/src/img/backward/fileBuffer.png)

We will get that `remain = SizeOfHeaders - sizeof(DOSHeader) - rubbish data - PE SIGNATURE - sizeof(FileHeader) - sizeof(OptionalHeader) - sizeof(section table)`

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

From the struct of a section header, we know that the size of it is 40(0x28) bytes. We need at least two section headers - one is reserved for new section and the other (all zero) is for checking end of section as requested by Win32 system.

![Add New Section](codehome/src/img/backward/addNewSection.png)

Therefore, there must have at least a memory space with the size of two section headers, `remain >= sizeof(two section headers) == 80 bytes`.

BTW, what if there is no space to add a new section header in section table though it is happened in a tiny possibility. Our solution is to extend the size of the last section header, that is `Misc` and `SizeOfRawData`.

##### Modification

- Add two new sections to section table.
- Modify the value of NumberOfSections in FileHeader.
- Modify the value of SizeOfImage.
- Add a new section at the end of the last section, since it will keep original code address unchanged.
- Update Characteristics of new section in section table.

### C

Now let's achieve it with C. The only difference from the code above (`TEST_AddShellCodeToCodeSection()`) is that we have to create a new memory space.

```c
// Tools.h

// AddSectionToBuffer
//     The function will add a new section to file buffer
// @fileBuffer: the base address of file buffer.
// @newSection: a pointer to a struct of section header.
// @newFileBuffer: the base address of new file buffer whose space is extended.
STATUS AddSectionToBuffer(IN PMEMORYBASE fileBuffer, IN IMAGE_SECTION_HEADER* newSection, OUT PMEMORYBASE* newFileBuffer);

// TEST_AddSectionToBuffer():
//     This function will add a new section to a file buffer.
void TEST_AddSectionToBuffer();
```

```c
// Tools.c
STATUS AddSectionToBuffer(IN PMEMORYBASE fileBuffer, IN IMAGE_SECTION_HEADER* newSection, OUT PMEMORYBASE* newFileBuffer) {
	PMEMORYBASE newBuffer = nullptr;
	DWORD filesize = calculateFileBufferSize(fileBuffer);
	DWORD newFilesize = 0;
	BYTE* startPoint = nullptr;
	DWORD numOfLastSection = pFileHeader->NumberOfSections - 1;

	// TODO: check if there is enough space for new section
	DWORD remain = 0;
	remain = pOptionalHeader->SizeOfHeaders - pDosHeader->e_lfanew - IMAGE_SIZEOF_PE_SIGNATURE - IMAGE_SIZEOF_FILE_HEADER - pFileHeader->SizeOfOptionalHeader - pFileHeader->NumberOfSections * IMAGE_SIZEOF_SECTION_HEADER;
	if (remain < 2 * IMAGE_SIZEOF_SECTION_HEADER) {
		printf("No memory available for a new section header.\n");
		return 255;
	}
	
	// TODO: update value of new section
	newSection->Characteristics = newSection->Characteristics | 0x60000020;
	// file alignment
	newSection->SizeOfRawData = ((newSection->Misc.PhysicalAddress - 1) / pOptionalHeader->FileAlignment + 1) * pOptionalHeader->FileAlignment;
	// section alignment
	newSection->PointerToRawData = p_section_header[numOfLastSection].PointerToRawData + p_section_header[numOfLastSection].SizeOfRawData;
	newSection->VirtualAddress = p_section_header[numOfLastSection].VirtualAddress + ((p_section_header[numOfLastSection].SizeOfRawData - 1) / pOptionalHeader->SectionAlignment + 1) * pOptionalHeader->SectionAlignment;

	// TODO: modify the SizeOfImage, section alignment IMPORTANT
	pOptionalHeader->SizeOfImage = newSection->VirtualAddress + ((newSection->SizeOfRawData - 1) / pOptionalHeader->SectionAlignment + 1) * pOptionalHeader->SectionAlignment;

	// TODO: copy new section to section table
	startPoint = (BYTE*)((DWORD)&p_section_header[numOfLastSection+1]);
	memcpy(startPoint, newSection, IMAGE_SIZEOF_SECTION_HEADER);
	startPoint = (BYTE*)((DWORD)&p_section_header[numOfLastSection+2]);
	memset(startPoint, 0, IMAGE_SIZEOF_SECTION_HEADER);

	// TODO: modify the value of NumberOfSections in FileHeader.
	pFileHeader->NumberOfSections += 1;

	// TODO: add a new section at the end of the last section
	newFilesize = filesize + newSection->SizeOfRawData;
	newBuffer = (PMEMORYBASE)malloc(sizeof(BYTE) * newFilesize);
	memset(newBuffer, 0, sizeof(BYTE) * newFilesize);
	memcpy(newBuffer, fileBuffer, filesize);

	*newFileBuffer = newBuffer;
	newBuffer = nullptr;
	
	return 0;
}

void TEST_AddSectionToBuffer() {
	STATUS ret;
	PMEMORYBASE newFileBuffer;
	IMAGE_SECTION_HEADER* newSection;
	char name[SIZEOF_SECTION_NAME] = { 0x2e, 'b', 'c', 'b',
					'c'};

	// initialize global pointers
	fileBuffer = nullptr;
	pDosHeader = nullptr;
	pFileHeader = nullptr;
	pOptionalHeader = nullptr;

	ret = PEReader("notepad.exe", &fileBuffer);
	ret = PEParser(fileBuffer);
	printHeaders();

	// TODO: allocate a new section
	newSection = (IMAGE_SECTION_HEADER*)malloc(sizeof(IMAGE_SECTION_HEADER));
	memset(newSection, 0, sizeof(IMAGE_SECTION_HEADER));
	memcpy(&newSection->Name, name, SIZEOF_SECTION_NAME);
	newSection->Misc.PhysicalAddress = 0x00001000;
	
	ret = AddSectionToBuffer(fileBuffer, newSection, &newFileBuffer);
	ret = PEParser(newFileBuffer);
	printHeaders();

 	ret = SaveBufferAsFile("notepad_ext.exe", newFileBuffer);
	free(fileBuffer);
	free(newFileBuffer);
}
```

```c
// Output:
...
Description of SECTION 2:
Name: .rsrc
Misc: 7f30
VirtualAddress: b000
SizeOfRawData: 8000
PointerToRawData: 8400
Characteristics: 40000040

Description of SECTION 3:
Name: .bcbc
Misc: 1000
VirtualAddress: 13000
SizeOfRawData: 1000
PointerToRawData: 10400
Characteristics: 60000020
```

Notice that when file/section aligning data, we minus one to `Misc` or `SizeOfRawData`. That's a trick to avoid add one more alignment when `Misc` or `SizeOfRawData` is the multiple of file/section alignment.

##### Fix Bugs

Yet, when we execute new notepad, alas!

![DLL Indexing Error](codehome/src/img/backward/dllError.png)

Take a look back to original notepad, we will find there is some .dll indexing code right after section table. However, we overwrite it!

![DLL Indexing Code](codehome/src/img/backward/dllIndexing.png)

There is one way to fix it: elevate headers since we know that there is some trash code after DOSHeader.

```c
// Tools.c: fixed code
STATUS AddSectionToBuffer(IN PMEMORYBASE fileBuffer, IN IMAGE_SECTION_HEADER* newSection, OUT PMEMORYBASE* newFileBuffer) {
	DWORD new_e_lfanew = 0x40;
	...
	// TODO: modify the SizeOfImage, section alignment IMPORTANT
	pOptionalHeader->SizeOfImage = newSection->VirtualAddress + ((newSection->SizeOfRawData - 1) / pOptionalHeader->SectionAlignment + 1) * pOptionalHeader->SectionAlignment;
	
	// TODO: elevate headers if they are not elevated
	if (pDosHeader->e_lfanew > new_e_lfanew) {
		sizeOfHeadersFromPESignature = IMAGE_SIZEOF_PE_SIGNATURE + IMAGE_SIZEOF_FILE_HEADER + pFileHeader->SizeOfOptionalHeader + pFileHeader->NumberOfSections * IMAGE_SIZEOF_SECTION_HEADER;
		memcpy((PMEMORYBASE)((DWORD)fileBuffer + new_e_lfanew), (PMEMORYBASE)((DWORD)fileBuffer + pDosHeader->e_lfanew), sizeOfHeadersFromPESignature);
		pDosHeader->e_lfanew = new_e_lfanew;
		// update pointers to headers
		PEParser(fileBuffer);
	}

	// copy new section to section table
	...
}
```

### Add to a New Section

After adding a new section, then we will add shell code to the new section. The method is same as one in the first part, `Add to Code Section`.

```bash
# Add shell code
-- Entry Point --| - - - - X - - - -|-- Original Code -->
                 |                  |
            call |                  | jmp
                 |                  |
                 |->- Shell Code ->-|
```

Now let's program to achieve it.

```c
// Tools.h
// TEST_AddShellCodeToNewSection:
//     This function will add a new shell code to a new section.
void TEST_AddShellCodeToNewSection();
```

```c
// Tools.c
void TEST_AddShellCodeToNewSection() {
	STATUS ret;
	PMEMORYBASE newFileBuffer;
	IMAGE_SECTION_HEADER* newSection;
	DWORD num_of_new_section = 0;
	char name[SIZEOF_SECTION_NAME] = { 0x2e, 'b', 'c', 'b',
					'c'};
	BYTE SHELL_CODE[] = { 0x6A, 0x00, 0x6A, 0x00, 0x6A, 0x00, 0x6A, 0x00,
						  0xE8, 0x00, 0x00, 0x00, 0x00, 0xE9, 0x00, 0x00,
						  0x00, 0x00 };
	BYTE* AddrOfMessageBox = (BYTE*)0x77D5050B;
	BYTE* startPoint = nullptr;
	BYTE* virtualAddress = nullptr;
	BYTE* addr_in_hardcode = nullptr;
	BYTE* EntryPoint;

	// initialize global pointers
	fileBuffer = nullptr;
	pDosHeader = nullptr;
	pFileHeader = nullptr;
	pOptionalHeader = nullptr;

	ret = PEReader("notepad.exe", &fileBuffer);
	ret = PEParser(fileBuffer);

	newSection = (IMAGE_SECTION_HEADER*)malloc(sizeof(IMAGE_SECTION_HEADER));
	memset(newSection, 0, sizeof(IMAGE_SECTION_HEADER));
	memcpy(&newSection->Name, name, SIZEOF_SECTION_NAME);
	newSection->Misc.PhysicalAddress = 0x00001000;
	
	// add a new code section
	ret = AddSectionToBuffer(fileBuffer, newSection, &newFileBuffer);

	// TODO: save new buffer to global fileBuffer
	free(fileBuffer);
	fileBuffer = newFileBuffer;
	newFileBuffer = nullptr;
	ret = PEParser(fileBuffer);
	printHeaders();
	
	// TODO: copy shell code to new section
	// 6A 00 6A 00 6A 00 6A 00 E8 00 00 00 00 E9 00 00 00 00 
	num_of_new_section = pFileHeader->NumberOfSections - 1;
	startPoint = (BYTE*)((DWORD)fileBuffer + p_section_header[num_of_new_section].PointerToRawData);
	memcpy(startPoint, SHELL_CODE, sizeof(SHELL_CODE));

	// TODO: update hard code address
	// copy hard code of call address to memory space next to E8
	// 6A 00 6A 00 6A 00 6A 00 E8 FE D4 D3 76 E9 00 00 00 00 
	virtualAddress = FOAToVA(startPoint + 8, (BYTE*)pOptionalHeader->ImageBase);
	addr_in_hardcode = (BYTE*)((DWORD)AddrOfMessageBox - (DWORD)virtualAddress - 5);
	memcpy(startPoint + 9, &addr_in_hardcode, sizeof(DWORD));
	
	// copy hard code of jmp address to memory space next to E9
	// 6A 00 6A 00 6A 00 6A 00 E8 FE D4 D3 76 E9 8B 43 FF FF 
	EntryPoint = (BYTE*)((DWORD)pOptionalHeader->ImageBase + (DWORD)pOptionalHeader->AddressOfEntryPoint);
	virtualAddress = FOAToVA(startPoint + 13, (BYTE*)pOptionalHeader->ImageBase);
	addr_in_hardcode = (BYTE*)((DWORD)EntryPoint - (DWORD)virtualAddress - 5);
	memcpy(startPoint + 14, &addr_in_hardcode, sizeof(DWORD));

	// modify AddressOfEntryPoint to start point
	virtualAddress = FOAToVA(startPoint, (BYTE*)pOptionalHeader->ImageBase);
	// minus ImageBase
	virtualAddress = (BYTE*)((DWORD)virtualAddress - pOptionalHeader->ImageBase);
	memcpy(&pOptionalHeader->AddressOfEntryPoint, &virtualAddress, sizeof(DWORD));

	// save as a file
	ret = SaveBufferAsFile("notepad_ext.exe", fileBuffer);
	free(fileBuffer);
}
```

Notice that we save new buffer to global fileBuffer in order to keep uniform of all codes.

<EndMarkdown>