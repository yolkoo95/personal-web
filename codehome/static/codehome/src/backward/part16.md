# PE Seg.7

## Table of Contents
- [DATA DIRECTORY](#datadirectory)
	- [Optional Header Data Directories](#optionalheaderdatadirectories)
	- [Export Data Section](#exportdatasection)
		- [Export Directory Table](#exportdirectorytable)
		- [Export Address Table](#exportaddresstable)
		- [Export Name Pointer Table](#exportnamepointertable)
		- [Export Ordinal Table](#exportordinaltable)
		- [Export Name Table](#exportnametable)
		- [Export Methods](#exportmethods)

<TableEndMark>

## DATA DIRECTORY

Notice that in the previous, we define optional header struct as follows,

```c
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
```

Yet it is not complete since we did NOT define image data directory. Now let's discuss these important directories.

### Optional Header Data Directories 

Each data directory gives the address and size of a table or string that Windows uses. These data directory entries are all loaded into memory so that the system can use them at run time. A data directory is an 8-byte field that has the following declaration:

```c
typedef struct _IMAGE_DATA_DIRECTORY {
    DWORD   VirtualAddress;
    DWORD   Size;
} IMAGE_DATA_DIRECTORY, *PIMAGE_DATA_DIRECTORY;
```

The first field, VirtualAddress, is actually the RVA of the table. The RVA is the address of the table relative to the base address of the image when the table is loaded. The second field gives the size in bytes. The data directories, which form the last part of the optional header, are listed in the following table.

Note that the number of directories is not fixed. Before looking for a specific directory, check the `NumberOfRvaAndSizes` field in the optional header.

| Offset | Size | Field | Description |
| :---: | :---: | :---: | :---: |
| 96 | 8 | Export Table | The export table address and size |
| 104 | 8 | Import Table | The import table address and size. For more information |
| 112 | 8 | Resource Table | The resource table address and size. For more information |
| 120 | 8 | Exception Table | The exception table address and size. For more information |
| 128 | 8 | Certificate Table | The attribute certificate table address and size. For more information | 
| 136 | 8 | Base Relocation Table | The base relocation table address and size. For more information |
| ... | ... | ... | ... |
| 192 | 8 | IAT | The import address table address and size. |
| ... | ... | ... | ... |

Although there are so many items, we only focus on 4 tables of them - export table, import table, base relocation table, and IAT.

### Export Data Section

The export data section, named .edata, contains information about symbols that other images can access through dynamic linking. Exported symbols are generally found in DLLs, but DLLs can also import symbols.

An overview of the general structure of the export section is described below. 

| Table Name | Description |
| :---: | :---: |
| Export Directory Table | This table indicates the locations and sizes of the other export tables. |
| Export Address Table |  An array of RVAs of exported symbols. These are the actual addresses of the exported functions and data within the executable code and data sections. Other image files can import a symbol by using an index to this table (an ordinal) or, optionally, by using the public name that corresponds to the ordinal if a public name is defined. |
| Name Pointer Table | An array of pointers to the public export names, sorted in ascending order. |
| Ordinal table | An array of the ordinals that correspond to members of the name pointer table. The correspondence is by position; therefore, *the name pointer table and the ordinal table must have the same number of members*. Each ordinal is an index into the export address table. |
| Export Name Table | A series of null-terminated ASCII strings. Members of the name pointer table point into this area. These names are the public names through which the symbols are imported and exported; they are not necessarily the same as the private names that are used within the image file. |

#### Export Directory Table

The export symbol information begins with the **export directory table**, which describes the remainder of the export symbol information. The export directory table contains address information that is used to resolve imports to the entry points within this image.

```c
typedef struct _IMAGE_EXPORT_DIRECTORY {					
    DWORD   Characteristics;	
    DWORD   TimeDateStamp;	
    WORD    MajorVersion;
    WORD    MinorVersion;	
    DWORD   NameRVA;	
    DWORD   Ordinal Base;
    DWORD   NumberOfFunctions;
    DWORD   NumberOfNames;	
    DWORD   AddressOfFunctions;
    DWORD   AddressOfNames;
    DWORD   AddressOfNameOrdinals;
} IMAGE_EXPORT_DIRECTORY, *PIMAGE_EXPORT_DIRECTORY;					
```

| Offset |	Size |	Field |	Description |
| :---: | :---: | :---: | :---: |
| 0 | 4 | Export Flags | Reserved, must be 0. |
| 4 | 4 | Time/Date Stamp | The time and date that the export data was created. |
| 8 | 2 | Major Version | The major version number. The major and minor version numbers can be set by the user. |
| 10 | 2 | Minor Version | The minor version number. |
| 12 | 4 | Name RVA | The address of the ASCII string that contains the name of the DLL. This address is relative to the image base. |
| 16 | 4 | Ordinal Base | The starting ordinal number for exports in this image. This field specifies the starting ordinal number for the export address table. It is usually set to 1. |
| 20 | 4 | Address Table Entries | The number of entries in the export address table. |
| 24 | 4 | Number of Name Pointers | The number of entries in the name pointer table. This is also the number of entries in the ordinal table. |
| 28 | 4 | Export Address Table RVA | The address of the export address table, relative to the image base. |
| 32 | 4 | Name Pointer RVA | The address of the export name pointer table, relative to the image base. The table size is given by the Number of Name Pointers field. |
| 36 | 4 | Ordinal Table RVA | The address of the ordinal table, relative to the image base. | 

#### Export Address Table

The export address table contains the address of exported entry points and exported data and absolutes. An ordinal number is used as an index into the export address table.

Each entry in the export address table is a field that uses one of two formats in the following table. If the address specified is not within the export section (as defined by the address and length that are indicated in the optional header), the field is an export RVA, which is an actual address in code or data. Otherwise, the field is a forwarder RVA, which names a symbol in another DLL.

| Offset |	Size |	Field |	Description |
| :---:	 | :---: | :---: | :---: |
| 0 | 4 | Export RVA | The address of the exported symbol when loaded into memory, relative to the image base. For example, the address of an exported function. |
| 0 | 4 | Forwarder RVA | The pointer to a null-terminated ASCII string in the export section. This string must be within the range that is given by the *export table data directory* entry. This string gives the DLL name and the name of the export (for example, "MYDLL.expfunc") or the DLL name and the ordinal number of the export (for example, "MYDLL.#27"). |

Notice that:

- The number of address array is determined by NumberOfFunctions in export directory table.
- All address stored in array is RVA, and the absolute virtual address equals `RVA + ImageBase`.
- NumberOfFunctions: is calculated by biased ordinals defined by programmer.

For example, if we define `.def` file as follows,

```c
EXPORTS

Plus  @2
Sub   @5  NONAME
Mul   @3
Div   @6
```

Ordinals in `.def` file is called biased ordinal, and `NumberOfFunctions = Max - Min + 1`, which equals 5 in this case. We will get a corresponding export address table as follows,

```c
// export address table
index   value
0       100f
1       1014
2       0
3       100a
4       1019
```

#### Export Name Pointer Table

The export name pointer table is an array of addresses (RVAs) into the export name table. The pointers are 32 bits each and are relative to the image base. *The pointers are ordered lexically to allow binary searches.*

An export name is defined only if the export name pointer table contains a pointer to it.

#### Export Ordinal Table

The export ordinal table is an array of *16-bit unbiased indexes* into the export address table. Ordinals are biased by the Ordinal Base field of the export directory table. In other words, *the ordinal base must be subtracted from the ordinals to obtain true indexes into the export address table*.

The export name pointer table and the export ordinal table form two *parallel arrays* that are separated to allow natural field alignment. These two tables, in effect, operate as one table, in which *the Export Name Pointer column points to a public (exported) name and the Export Ordinal column gives the corresponding ordinal for that public name*. A member of the export name pointer table and a member of the export ordinal table are associated by having the same position (index) in their respective arrays.

Thus, when the export name pointer table is searched and a matching string is found at position i, the algorithm for finding the symbol's RVA and biased ordinal is:

```c
// search by name
i = Search_ExportNamePointerTable(name);
ordinal = ExportOrdinalTable[i];

rva = ExportAddressTable[ordinal];
biased_ordinal = ordinal + OrdinalBase;
```

When searching for a symbol by (biased) ordinal, the algorithm for finding the symbol's RVA and name is:

```c
ordinal = biased_ordinal - OrdinalBase;
i = Search_ExportOrdinalTable(ordinal);

rva = ExportAddressTable[ordinal];
name = ExportNameTable[i];
```

BTW, we will explain codes above in a minute, so if you feel confused, don't worry.

Notice that:

- Each element of array takes 2 bytes.
- Only functions with name can be accessed by names, Otherwise we have to access those without name by ordinals.

##### Differences Between Ordinal and Biased Ordinal

To make it clear, let's take an example, if we define a `.def` file as follows,

```c
EXPORTS

Plus  @2
Sub   @5  NONAME
Mul   @3
Div   @6
```

Ordinals above is termed biased ordinal, and the corresponding export ordinal table is:

```c
// export ordinal table, baseOrdinal is the minimum biased ordinal, 2.
index   value
0       4
1       1
2       0
```

From the example, we know that since the number of export ordinal table equals to that of export name pointer table, we are not able to access function with `NONAME` symbol by searching by name. In this case there is no ordinal in export ordinal table for `Sub`, a no-name function.

```c
// export address table
index   value
0       100f
1       1014
2       0
3       100a  // Sub(): cannot be searched by name
4       1019
```

#### Export Name Table

The export name table contains the actual string data that was pointed to by the export name pointer table. The strings in this table are public names that other images can use to import the symbols. These public export names are not necessarily the same as the private symbol names that the symbols have in their own image file and source code, although they can be.

Every exported symbol has an ordinal value, which is just the index into the export address table. Use of export names, however, is optional. Some, all, or none of the exported symbols can have export names. For exported symbols that do have export names, corresponding entries in the export name pointer table and export ordinal table work together to associate each name with an ordinal.

The structure of the export name table is a series of null-terminated ASCII strings of variable length.

#### Export Methods

There are two ways for export functions - by name or ordinal. The relationship of them can be diagrammed as follows,

![Relationship of Tables](codehome/src/img/backward/relationship.png)

```c
// update PEParser so that it is able to parse directory tables.
// Global.h: define struct of image data directory.
typedef struct image_data_directory {
	DWORD VirtualAddress;
	DWORD Size;
} IMAGE_DATA_DIRECTORY;
IMAGE_DATA_DIRECTORY* pDirectory;

///////////////////////////
// Export Table - Begin

typedef struct image_export_directory {					
    DWORD   Characteristics;	
    DWORD   TimeDateStamp;	
    WORD    MajorVersion;
    WORD    MinorVersion;	
    DWORD   NameRVA;	
    DWORD   OrdinalBase;
    DWORD   NumberOfFunctions;
    DWORD   NumberOfNames;	
    DWORD   AddressOfFunctions;
    DWORD   AddressOfNames;
    DWORD   AddressOfNameOrdinals;
} IMAGE_EXPORT_DIRECTORY;
IMAGE_EXPORT_DIRECTORY* pExportDirectory;

typedef struct export_address_table {
	DWORD FuncVirtualAddress;
} EXPORT_ADDRESS_TABLE;
EXPORT_ADDRESS_TABLE* pAddressTable;

typedef struct name_pointer_table {
	DWORD NameVirtualAddress;
} NAME_POINTER_TABLE;
NAME_POINTER_TABLE* pNamePointerTable;

typedef struct name_ordinal_table {
	WORD Ordinal;
} NAME_ORDINAL_TABLE;
NAME_ORDINAL_TABLE* pNameOrdinalTable;

// Export Table - End
///////////////////////

```

Notice that to fix dependency conflict, we place functions `VAToFOA()` and `FOAToVA()` in `Global.h` so that they are able to be used in `PEParser`.

```c
// PEParser.h: defines a constant directory offset to optional header, which is 96.
#define DIRECTORY_OFFSET 96

// add a new function print export directory
void printExportDirectory();
```

```c
// PEParser.c: lists 4 important tables -- export/import table, base relocation table, and important address table.
void printHeaders() {
	...
	printf("======Directory Data======\n");
	printf("Export Table: \n");
	printf("VA: %x,  Size: %x\n", pDirectory[0].VirtualAddress, pDirectory[0].Size);
	printf("Import Table: \n");
	printf("VA: %x,  Size: %x\n", pDirectory[1].VirtualAddress, pDirectory[1].Size);
	printf("Base Relocation Table: \n");
	printf("VA: %x,  Size: %x\n", pDirectory[5].VirtualAddress, pDirectory[5].Size);
	// since 13th table is IAT
	if (pOptionalHeader->NumberOfRvaAndSizes > 0x0C) {
		printf("IAT: \n");
		printf("VA: %x,  Size: %x\n", pDirectory[12].VirtualAddress, pDirectory[12].Size);
	}
	...
}

void printExportDirectory() {
	size_t i;
	printf("======Export Directory======\n");
	printf("Characteristics: %x\n", pExportDirectory->Characteristics);
	printf("TimeDateStamp: %x\n", pExportDirectory->TimeDateStamp);
	printf("MajorVersion: %x\n", pExportDirectory->MajorVersion);
	printf("MinorVersion: %x\n", pExportDirectory->MinorVersion);
	printf("Name RVA: %x\n", pExportDirectory->NameRVA);
	printf("Ordinal Base: %x\n", pExportDirectory->OrdinalBase);
	printf("NumberOfFunctions: %x\n", pExportDirectory->NumberOfFunctions);
	printf("NumberOfNames: %x\n", pExportDirectory->NumberOfNames);
	printf("AddressOfFunctions: %x\n", pExportDirectory->AddressOfFunctions);
	printf("AddressOfNames: %x\n", pExportDirectory->AddressOfNames);
	printf("AddressOfNameOrdinals: %x\n", pExportDirectory->AddressOfNameOrdinals);
	printf("\n");

	printf("======Function Address Table======\n");
	for (i = 0; i < pExportDirectory->NumberOfFunctions; i++) {
		printf("func@%d: %x\n", i, pAddressTable[i].FuncVirtualAddress);
	}
	printf("\n");

	printf("======Name Ordinal Table======\n");
	for (i = 0; i < pExportDirectory->NumberOfNames; i++) {
		printf("%d: %x\n", i, pNameOrdinalTable[i].Ordinal);
	}
	printf("\n");

	printf("======Name Pointer Table======\n");
	for (i = 0; i < pExportDirectory->NumberOfNames; i++) {
		printf("%d: %x --> ", i, pNamePointerTable[i].NameVirtualAddress);
		printf("@%s\n", VAToFOA((BYTE*)(pNamePointerTable[i].NameVirtualAddress + pOptionalHeader->ImageBase), fileBuffer));
	}
	printf("\n");
}

STATUS PEParser(IN PMEMORYBASE filebase) {
	...
	// TODO: Update directory pointer
	pDirectory = (IMAGE_DATA_DIRECTORY*)((DWORD)pOptionalHeader + DIRECTORY_OFFSET);

	// TODO: Update export directory
	// since virtual address here is rva according to our definition, we have to add image base to transfer it to va.
	pExportDirectory = VAToFOA((BYTE*)(pDirectory[0].VirtualAddress + pOptionalHeader->ImageBase), fileBuffer);
	pAddressTable = VAToFOA((BYTE*)(pExportDirectory->AddressOfFunctions + pOptionalHeader->ImageBase), fileBuffer);
	pNamePointerTable = VAToFOA((BYTE*)(pExportDirectory->AddressOfNames + pOptionalHeader->ImageBase), fileBuffer);
	pNameOrdinalTable = VAToFOA((BYTE*)(pExportDirectory->AddressOfNameOrdinals + pOptionalHeader->ImageBase), fileBuffer);
	...
}
```

##### Export by Name

Notice that in the last note, we use a builtin function called `GetProcAddress('FUNC_NAME')`. Now let's figure out how it works.

When the export name pointer table is searched and a matching string is found at position i, the algorithm for finding the symbol's RVA and biased ordinal is:

```c
// search by name pseudo code
i = Search_ExportNamePointerTable(name);
ordinal = ExportOrdinalTable[i];

rva = ExportAddressTable[ordinal];
biased_ordinal = ordinal + OrdinalBase;
```

```c
// Tools.h
// searchExportNamePointerTable:
//     The helper function for SearchFuncAddrByName, which will return the index of matching element in export name pointer table.
// @name: the name of function to be searched.
size_t searchExportNamePointerTable(char* name);

// SearchFuncAddrByName:
//     The function will search function address in image by function name.
// @buffer: the base address of memory buffer.
// @name: function name.
DWORD SearchFuncAddrByName(IN PMEMORYBASE buffer, char* name);
```

```c
// Tools.c
int isMatched(BYTE* foaAddr, BYTE* name) {
	if (strcmp(foaAddr, name)) {
		return 1;
	}
	else {
		return 0;
	}
}

size_t searchExportNamePointerTable(char* name) {
	size_t index = -1;
	size_t i = 0;
	BYTE* nameFOAAddr = nullptr;
	
	for (i = 0; i < pExportDirectory->NumberOfNames; i++) {
		nameFOAAddr = VAToFOA((BYTE*)(pNamePointerTable[i].NameVirtualAddress + pOptionalHeader->ImageBase), fileBuffer);
		if (isMatched(nameFOAAddr, name)) {
			index = i;
			break;
		}
	}

	return index;
}

DWORD SearchFuncAddrByName(IN PMEMORYBASE buffer, char* name) {
	WORD ordinal;
	DWORD rva;
	size_t i = searchExportNamePointerTable(name);
	
	if (i == -1) {
		printf("No matching function name founded.\n");
		exit(-1);
	}

	ordinal = pNameOrdinalTable[i].Ordinal;
	
	rva = pAddressTable[ordinal].FuncVirtualAddress;
	
	return rva;
}
```

![Search by Name](codehome/src/img/backward/searchByName.png)

IMPORTANT: if a function has no name, it can NOT be accessed by name.

```c
// GetFuncAddrByName(FileBuffer, Name)
```

##### Export by Ordinal

When searching for a symbol by (biased) ordinal, the algorithm for finding the symbol's RVA and name is:

```c
// search by ordinal pseudo code
ordinal = biased_ordinal - OrdinalBase;
i = Search_ExportOrdinalTable(ordinal);

rva = ExportAddressTable[ordinal];
name = ExportNameTable[i];
```

![Search by Ordinal](codehome/src/img/backward/searchByOrdinal.png)

```c
// Tools.h
// searchNameOrdinalTable:
//     The function will search ordinal in name ordinal table, and return the index of matched element.
// @ordinal: the ordinal of function, NOT biased ordinal.
size_t searchNameOrdinalTable(WORD ordinal);

// SearchFuncAddrByOrdinal:
//     The function will search function address in image by biased ordinal.
// @buffer: the base address of memory buffer.
// @biasedOrdinal: function ordinal defined in .def file.
DWORD SearchFuncAddrByOrdinal(IN PMEMORYBASE buffer, WORD biasedOrdinal);
```

```c
// Tools.c
size_t searchNameOrdinalTable(WORD ordinal) {
	size_t index = -1;
	size_t i;

	for (i = 0; i < pExportDirectory->NumberOfNames; i++) {
		if (ordinal == pNameOrdinalTable[i].Ordinal) {
			index = i;
			break;
		}
	}

	return index;
}

DWORD SearchFuncAddrByOrdinal(IN PMEMORYBASE buffer, WORD biasedOrdinal) {
	DWORD rva;
	BYTE* name;
	WORD ordinal = biasedOrdinal - pExportDirectory->OrdinalBase;
	size_t index = searchNameOrdinalTable(ordinal);

	rva = pAddressTable[ordinal].FuncVirtualAddress;
	name = (BYTE*)(VAToFOA((BYTE*)(pNamePointerTable[index].NameVirtualAddress + pOptionalHeader->ImageBase), fileBuffer));

	printf("Name of function: %s\n", name);

	return rva;
}
```

<EndMarkdown>