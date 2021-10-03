# PE Seg.5

## Table of Contents
- [Misc and SRD](#miscandsrd)
- [Section Extension](#sectionextension)
	- [Procedure](#procedure)
	- [C Program](#cprogram)
- [Section Merging](#sectionmerging)
	- [Method](#method)
	- [C](#c)

<TableEndMark>

<!-- Insert content here -->
## Misc and SRD

Now let's go back to the concept of `Misc`, which is an union of `VirtualSize` and `PhysicalAddress`, that of and `SizeOfRawData`(SRD).

```c
// notepad.exe
SectionHeader[1] {
    Name: .data
    Misc: 1ba8
    VirtualAddress: 9000 // VirtualAddress[1] = VirtualAddress[0] + SectionAlignment(SizeOfRawData[0])
    SizeOfRawData: 800
    PointerToRawData: 7c00 // PointerToRawData[1] = PointerToRawData[0] + SizeOfRawData[0]
    Characteristics: c0000040
}
```

Surprisingly, `Misc.VirtualSize` is bigger than `SizeOfRawData`, why?

`SizeOfRawData` is the size of the section (for object files) or the size of the **initialized data** on disk (for image files) **after file alignment**. For executable images, this must be a multiple of FileAlignment from the optional header. 

VirtualSize can be more or less than `SizeOfRawData`. 

- We for example can have only several bytes of initialized actual data in section and no uninitialized data - so VirtualSize will be only several bytes size, while `SizeOfRawData` 512 bytes. 
- In another case in .data or .bss section - can be no initialized data at all (so `SizeOfRawData == 0`) but `VirtualSize != 0`.

Therefore, in general if there are uninitialized data far more than initialized one, `Misc.VirtualSize`, which is the real size (no alignment) of data when program is loaded into memory, is highly likely to be greater than `SizeOfRawData`. More specifically, if `(size of uninitialized data) > (zero-filled padding)`, then `Misc.VirtualSize` is greater than `SizeOfRawData`.

## Section Extension

Assuming a scenario that there is no space for a new section header, then how could we create a safe space for our shell code? The straight answer is extension of the last section.

### Procedure

![Extension of Last Section](codehome/src/img/backward/SectionExtension.png)

What we have to do first is stretch memory as system do when loading image, and then allocate a block of memory after the end of last section. Next in order to keep the original data unchanged, **we treat original section memory as raw data (including original raw data and zero-filled padding for section alignment)**. Therefore, the new raw data contains three parts - original raw data, padding zeros, and extension memory. At last, we have to transfer image buffer to file buffer for saving as a file.

Notice that after section extension, the size of new file is greater than the old.

So which members are going to change:

- SizeOfImage: `SizeOfImage + sizeof(EXT)` 
- LastSection.VirtualSize: `SectionAlignment(SectionAlignment(MAX(SizeOfRawData, VirtualSize)) + sizeof(EXT))`
- LastSection.SizeOfRawData: `FileAlignment(SectionAlignment(MAX(SizeOfRawData, VirtualSize)) + sizeof(EXT))`

Why `MAX(SizeOfRawData, VirtualSize)`? In order to keep the original data unchanged, since `SizeOfRawData` can be greater or less than `VirtualSize`.

### C Program

Here we define a helper function `align()`, which return the size after alignment.

```c
// Tools.h
// align:
//     This function will return a size aligned by given align size.
// @size: size of data.
// @alignSize: size of alignment.
DWORD align(DWORD size, DWORD alignSize);

// Tools.c
DWORD align(DWORD size, DWORD alignSize) {
	DWORD ret = ((size - 1) / alignSize + 1) * alignSize;
	return ret;
}
```

Now, let's do it.

```c
// Tools.h
// ExtensionOfLastSection:
//     The function will extend the size of last section
// @fileBuffer: the base address of file buffer.
// @addition: the size to be extended.
// @newFileBuffer: the base address of new file buffer whose last section is extended.
STATUS ExtensionOfLastSection(IN PMEMORYBASE fileBuffer, IN DWORD addition, OUT PMEMORYBASE* newFileBuffer);

// TEST_ExtensionOfLastSection:
//     This function will extend the size of last section.
void TEST_ExtensionOfLastSection();
```

```c
// Tools.c
STATUS ExtensionOfLastSection(IN PMEMORYBASE fileBuffer, IN DWORD addition, OUT PMEMORYBASE* newFileBuffer) {
	STATUS ret;
	PMEMORYBASE imgBuffer = nullptr;
	PMEMORYBASE imgBuffer_ext = nullptr;
	DWORD last = pFileHeader->NumberOfSections - 1;
	DWORD newSize = 0;

	ret = FileBufferToImageBuffer(fileBuffer, &imgBuffer);

	// TODO: allocate new img buffer and modify SizeOfImage
	imgBuffer_ext = (PMEMORYBASE)malloc(sizeof(BYTE) * pOptionalHeader->SizeOfImage + addition);
	memset(imgBuffer_ext, 0, sizeof(BYTE) * pOptionalHeader->SizeOfImage + addition);
	memcpy(imgBuffer_ext, imgBuffer, pOptionalHeader->SizeOfImage);

	// parse members of new buffer, IMPORTANT
	ret = PEParser(imgBuffer_ext);

	pOptionalHeader->SizeOfImage += addition;

	// TODO: modify section header of the last one
	newSize = p_section_header[last].Misc.VirtualSize > p_section_header[last].SizeOfRawData ? p_section_header[last].Misc.VirtualSize : p_section_header[last].SizeOfRawData;
	p_section_header[last].Misc.VirtualSize = align(align(newSize, pOptionalHeader->SectionAlignment) + addition, pOptionalHeader->SectionAlignment);
	p_section_header[last].SizeOfRawData = align(align(newSize, pOptionalHeader->SectionAlignment) + addition, pOptionalHeader->FileAlignment);

	// TODO: save as file buffer
	ret = ImageBufferToFileBuffer(imgBuffer_ext, newFileBuffer);

	free(imgBuffer);
	free(imgBuffer_ext);

	return 0;
}

void TEST_ExtensionOfLastSection() {
	PMEMORYBASE newFileBuffer = nullptr;
	STATUS ret;

	// initialize global pointers
	fileBuffer = nullptr;
	pDosHeader = nullptr;
	pFileHeader = nullptr;
	pOptionalHeader = nullptr;

	ret = PEReader("notepad.exe", &fileBuffer);
	ret = PEParser(fileBuffer);
	printHeaders();
	ret = ExtensionOfLastSection(fileBuffer, 0x1000, &newFileBuffer);
	
	ret = SaveBufferAsFile("notepad_ext.exe", newFileBuffer);
	ret = PEParser(newFileBuffer);
	printHeaders();

	free(fileBuffer);
	free(newFileBuffer);
}
```

```c
// Output:
// notepad.exe:
OptionalHeader.SizeOfImage: 13000

Description of SECTION[0]{
    Name: .text
    Misc: 7748
    VirtualAddress: 1000
    SizeOfRawData: 7800
    PointerToRawData: 400
    Characteristics: 60000020
}

Description of SECTION[1]{
    Name: .data
    Misc: 1ba8
    VirtualAddress: 9000
    SizeOfRawData: 800
    PointerToRawData: 7c00
    Characteristics: c0000040
}

Description of SECTION[2]{
    Name: .rsrc
    Misc: 7f30
    VirtualAddress: b000
    SizeOfRawData: 8000
    PointerToRawData: 8400
    Characteristics: 40000040
}

// notepad_ext.exe:
OptionalHeader.SizeOfImage: 14000

Description of SECTION[0]{
    Name: .text
    Misc: 7748
    VirtualAddress: 1000
    SizeOfRawData: 7800
    PointerToRawData: 400
    Characteristics: 60000020
}

Description of SECTION[1]{
    Name: .data
    Misc: 1ba8
    VirtualAddress: 9000
    SizeOfRawData: 800
    PointerToRawData: 7c00
    Characteristics: c0000040
}

Description of SECTION[2]{
    Name: .rsrc
    Misc: 9000
    VirtualAddress: b000
    SizeOfRawData: 9000
    PointerToRawData: 8400
    Characteristics: 40000040
}
```

## Section Merging

Besides section extension, there is another common operation on section - section merging, which will reserve memory space in section header, but the size of file will be greater unfortunately.

### Method

![Section Merging](codehome/src/img/backward/SectionMerging.png)

The idea of merging section is somewhat similar to section extension. First stretch memory, and then treat all sections in image buffer as raw data (including raw data of each merged section and their zero-filled paddings). Finally transfer it to file buffer for saving file.

So which members are going to change (Assuming merging all section to the first section):

- FirstSection.VirtualSize: `SizeOfImage - FirstSection.VirtualAddress`, which is must be the multiple of `SectionAlignment`.
- FirstSection.SizeOfRawData: `FileAlignment(SizeOfImage - FirstSection.VirtualAddress)`.
- FirstSection.Characteristics: includes all characteristics of each original section.
- FileHeader.NumberOfSections: is modified to 1.

### C

```c
// Tools.h
// MergingSections:
//     The function will merge all sections into the first one
// @fileBuffer: the base address of file buffer.
// @newFileBuffer: the base address of new file buffer whose sections are merged.
STATUS MergingSections(IN PMEMORYBASE fileBuffer, OUT PMEMORYBASE* newFileBuffer);

// TEST_MergingSections:
//     This function will merge all sections into the first one.
void TEST_MergingSections();
```

```c
// Tools.c
STATUS MergingSections(IN PMEMORYBASE fileBuffer, OUT PMEMORYBASE* newFileBuffer) {
	STATUS ret;
	PMEMORYBASE imgBuffer = nullptr;
	DWORD newCharacteristics = 0;
	DWORD i;

	ret = FileBufferToImageBuffer(fileBuffer, &imgBuffer);
	
	// parse new buffer
	ret = PEParser(imgBuffer);
	
	// TODO: update members of new buffer
	// record characteristics of each section and update characteristics
	for (i = 0; i < pFileHeader->NumberOfSections; i++) {
		newCharacteristics = newCharacteristics | p_section_header[i].Characteristics;
	}
	p_section_header[0].Characteristics = newCharacteristics;
	// update virtual size
	p_section_header[0].Misc.VirtualSize = pOptionalHeader->SizeOfImage - p_section_header[0].VirtualAddress;
	// update size of raw data
	p_section_header[0].SizeOfRawData = align(p_section_header[0].Misc.VirtualSize, pOptionalHeader->FileAlignment);

	// update number of sections
	pFileHeader->NumberOfSections = 1;

	ret = ImageBufferToFileBuffer(imgBuffer, newFileBuffer);

	free(imgBuffer);

	return 0;
}

void TEST_MergingSections() {
	PMEMORYBASE newFileBuffer = nullptr;
	STATUS ret;

	// initialize global pointers
	fileBuffer = nullptr;
	pDosHeader = nullptr;
	pFileHeader = nullptr;
	pOptionalHeader = nullptr;

	ret = PEReader("notepad.exe", &fileBuffer);
	ret = PEParser(fileBuffer);
	printHeaders();

	ret = MergingSections(fileBuffer, &newFileBuffer);
	
	ret = SaveBufferAsFile("notepad_merge.exe", newFileBuffer);
	ret = PEParser(newFileBuffer);
	printHeaders();

	free(fileBuffer);
	free(newFileBuffer);
}
```

```c
// Output:
// notepad.exe:
FileHeader.NumberOfSections: 3

Description of SECTION[0]{
    Name: .text
    Misc: 7748
    VirtualAddress: 1000
    SizeOfRawData: 7800
    PointerToRawData: 400
    Characteristics: 60000020
}

Description of SECTION[1]{
    Name: .data
    Misc: 1ba8
    VirtualAddress: 9000
    SizeOfRawData: 800
    PointerToRawData: 7c00
    Characteristics: c0000040
}

Description of SECTION[2]{
    Name: .rsrc
    Misc: 7f30
    VirtualAddress: b000
    SizeOfRawData: 8000
    PointerToRawData: 8400
    Characteristics: 40000040
}

// notepad_merge.exe:
FileHeader.NumberOfSections: 1

Description of SECTION[0]{
    Name: .text
    Misc: 12000
    VirtualAddress: 1000
    SizeOfRawData: 12000
    PointerToRawData: 400
    Characteristics: e0000060
}
```

<EndMarkdown>