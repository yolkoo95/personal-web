# Base, Register and Assembly Language

## Table of Contents
- [Base](#base)
- [Data Size](#datasize)
      - [Signed and Unsigned Numbers](#signedandunsignednumbers)
- [Logic Operation](#logicoperation)
      - [How does a computer do calculation](#howdoesacomputerdocalculation)
- [Win32 Registers](#win32registers)
      - [Basic Command](#basiccommand)
- [Memory](#memory)
      - [Stack-based Memory Allocation](#stack-basedmemoryallocation)
      - [PUSH and POP](#pushandpop)
- [EFLAGS Registers](#eflagsregisters)
      - [Related Command](#relatedcommand)
- [Control Flow](#controlflow)

<TableEndMark>

## Base

A base is the available numbers in a numbering system. Forexample, the most commonly known base is a base-10 numbering system or decimal numbers, which are 0,1,2,3,4,5,6,7,8, and 9. Another common base when dealing with computers is the binary base-2, which only has the numbers 0 and 1.

- `Binary`: is a base-2 number system invented by Gottfried Leibniz that is made up of only two numbers: 0 and 1. This number system is the basis for all binary code, which is used to write data such as the computer processor instructions used every day.
- `Octal`: Octal is a base-8 number system commonly used to represent binary numbers and other numbers in a shorter form. Below is a basic chart of how a binary number is converted to an octal number.
- `Hex`: Alternatively referred to as base-16 or hex, the hexadecimal numbering system uses combinations of 16 character digits to represent numbers. Hexadecimal uses all ten numbers in the decimal system (0, 1, 2, 3, 4, 5, 6, 7, 8, and 9) and letters A through F. For example, "computer hope" in hexadecimal becomes "636f6d707574657220686f7065".

For programmers, something should be remembered,

```bash
0     1     2     3     4     5     6     7     8     9    
0000  0001  0010  0011  0100  0101  0110  0111  1000  1001
A     B     C     D     E     F
1010  1011  1100  1101  1110  1111
```

By the way, an important idea of base is that people could define their own base, a new defination of decimal system could be (2, 1, 3, 7, 8, 6, 5, 0, 9, 4) for example, where `100` we are used to use should be `122`, therefore, *the best way to be familiar with base is to write addition table and multiplication table under different base system*. Take 7-base system for example,

```shell
Addition Table
1+1=2					
1+2=3	2+2=4				
1+3=4	2+3=5	3+3=6			
1+4=5	2+4=6	3+4=10	4+4=11		
1+5=6	2+5=10	3+5=11	4+5=12	5+5=13	
1+6=10	2+6=11	3+6=12	4+6=13	5+6=14	6+6=15

Multiplication Table
1*1=1					
1*2=2	2*2=4				
1*3=3	2*3=6	3*3=12			
1*4=4	2*4=11	3*4=15	4*4=22		
1*5=5	2*5=13	3*5=21	4*5=26	5*5=34	
1*6=6	2*6=15	3*6=24	4*6=33	5*6=42	6*6=51
```

We need to keep one thing in heart that, the essense of operation in any numbering system is to *check tables*.

## Data Size

Data size refers to the number of bits of data that can be manufactured within the CPU at one given time.

- the data width of a computer is also called its word size.

- computers have data wide ranging from 8 bit to 64 bit.

1 byte = 8 bits, 1 word = 2 bytes(in 32bits architecture), 1 dword = 4 bytes = 32 bits(int 32bits architecture).

### Signed and Unsigned Numbers

#### Unsigned Numbers

Unsigned numbers don’t have any sign, these can contain only magnitude of the number. So, representation of unsigned binary numbers are all positive numbers only. For example, representation of positive decimal numbers are positive by default. We always assume that there is a positive sign symbol in front of every number.

So for a 8 bits system, the range is `0x00 ~ 0xFF`, which is from `0` to `255`.

#### Signed Numbers

There are three types of representations for signed binary numbers. Because of extra signed bit, binary number zero has two representation, either positive (0) or negative (1), so ambiguous representation. But 2’s complementation representation is unambiguous representation because of there is no double representation of number 0. These are: Sign-Magnitude form, 1’s complement form, and 2’s complement form which are explained as following below.

- Sign-Magnitude Form

For n bit binary number, 1 bit is reserved for sign symbol. If the value of sign bit is 0, then the given number will be positive, else if the value of sign bit is 1, then the given number will be negative. Remaining `(n-1)` bits represent magnitude of the number.

CONS: Since magnitude of number zero (0) is always 0, so there can be two representation of number zero (0), positive (+0) and negative (-0), which depends on value of sign bit. Hence these representations are ambiguous generally because of two representation of number zero (0).

For example, range of 8 bit sign-magnitude form binary number is from `-(2^7 - 1)` to `(2^7 - 1)`, which is from `-127` to `+127`, including `+0` and `-0`.

- 1’s Complement Form

Since, 1’s complement of a number is obtained by inverting each bit of given number. So, we represent positive numbers in binary form and negative numbers in 1’s complement form. There is extra bit for sign representation.If value of sign bit is 0, then number is positive and you can directly represent it in simple binary form, but if value of sign bit 1, then number is negative and you have to take 1’s complement of given binary number. You can get negative number by 1’s complement of a positive number and positive number by using 1’s complement of a negative number.

CONS: Therefore, in this representation, zero (0) can have two representation, that’s why 1’s complement form is also ambiguous form. The range of 1’s complement form is from  `-(2^(n-1) - 1)`  to `(2^(n-1) - 1)` .

Take 8-bit number for example, the maximum number is `01111111`, which is `127`, and the minimum number is `10000000`, which is `-127`. Also there are two zeros, `00000000` and `11111111` respectively.

- 2’s Complement Form

Since, 2’s complement of a number is obtained by inverting each bit of given number plus 1 to least significant bit (LSB). So, we represent positive numbers in binary form and negative numbers in 2’s complement form. There is extra bit for sign representation.You can get negative number by 2’s complement of a positive number and positive number by directly using simple binary representation. 

For an 8-bits number `00000111`, which is `7`, its 2's complement form is `11111000 + 1`, which is `11111001`.

Conclusion: for 8-bits number system, in hex form, the positive range is from `0x00` to `0x7F`, and the negtive range is from `0x80` to `0xFF`, noting that zero is included in positive range.

## Logic Operation

There are four basic operations in computer -- `OR`, `AND`, `XOR` and `NOT`.

| A | B | A AND B | A OR B | A XOR B | !A |
| :---: | :---: | :---:  | :---: | :---: |
| 1 | 1 | 1 | 1 | 0 | 0 |
| 0 | 1 | 0 | 1 | 1 | 1 |
| 1 | 0 | 0 | 1 | 1 | 0 |
| 0 | 0 | 0 | 0 | 0 | 1 |

### How does a computer do calculation

Let's think as a CPU, taking addition for example. The operation hidden behind the scene is `AND` and `XOR`.

```bash
# how does CPU compute `2 + 3`?
# let's take x = 0010, y = 0011

      0010            0010
XOR   0011      AND   0011
----------      ----------
      0001            0010      0010 << 1 = 0100

# as 0100 != 0000, calculation continues,
# take x = 0001, y = 0100

      0001            0001
XOR   0100      AND   0100
----------      ----------
      0101            0000      0000 << 1 = 0000
# as 0000 == 0000, calculation ends,
# and the result is 0101, which is 5
```

## Win32 Registers

| Register | Function | Code | Range |
| :---: | :---: | :---: | :---: |
| EAX | Accumulator | 0 | 0 - 0xFFFFFFFF |
| ECX | Counter | 1 | 0 - 0xFFFFFFFF |
| EDX | I/O Pointer | 2 | 0 - 0xFFFFFFFF |
| EBX | DS Data Pointer | 3 | 0 - 0xFFFFFFFF |
| ESP | Stack Top Pointer | 4 | 0 - 0xFFFFFFFF |
| EBP | Stack Bottom Pointer | 5 | 0 - 0xFFFFFFFF |
| ESI | System Pointer | 6 | 0 - 0xFFFFFFFF |
| EDI | ES Data Pointer | 7 | 0 - 0xFFFFFFFF |

```bash
# the structure of EAX

0000 0000 0000 0000 0000 0000 0000 0000
| <----------    EAX     -----------> |
                    | <---  AX  --->  |
					| <-AH->| |<-AL-> |

# ECX, EDX, EBX have the same structure as EAX
```

### Basic Command

- `MOV [DST], [ORI]`

```bash
# r: register, m: memory, imm: immediate, num: data size
# there are lots of MOV command for moving different data from one place to another, noting that we CANNOT move data FROM MEMORY TO MEMORY!

MOV r/m8, r8
# MOV AL, BL
# MOV AH, AL
# MOV BYTE PTR DST:[0x00FF238D], AL

MOV r/m16, r16
# MOV AX, BX
# MOV WORD PTR DST:[0X00FE2D3C], BX

MOV r/m32, r32
# MOV EAX, EBX
# MOV DWORD PTR DST:[0X00FD2EE3], EAX 

MOV r8, m8
MOV r16, m16
MOV r32, m32

MOV r8, imm8
MOV r16, imm16
MOV r32, imm32
```

- `ADD [DST], [ORI]`

```bash
ADD r/m8, r8
ADD r/m16, r16
ADD r/m32, r32

ADD r/m8, imm8
# ADD BYTE PTR DST:[0X00EF789C], 0xFE
ADD r/m16, imm16
ADD r/m32, imm32

ADD r8, m8
ADD r16, m16
# ADD AX, WORD PTR DST:[0X0009EF8C]
ADD r32, m32
```

- `SUB [DST], [ORI]`

```bash
SUB r/m8, r8
SUB r/m16, r16
SUB r/m32, r32

SUB r/m8, imm8
# SUB BYTE PTR DST:[0X00DD719C], 0xFE
SUB r/m16, imm16
SUB r/m32, imm32

SUB r8, m8
SUB r16, m16
# SUB AX, WORD PTR DST:[0X0009AC8C]
SUB r32, m32
```

- `AND [DST], [ORI]`

```bash
AND r/m8, r8
AND r/m16, r16
AND r/m32, r32

AND r/m8, imm8
# AND BYTE PTR DST:[0X01DE719C], 0xFF
AND r/m16, imm16
AND r/m32, imm32

AND r8, m8
AND r16, m16
# AND AX, WORD PTR DST:[0X0109FC8C]
AND r32, m32
```

- `OR [DST], [ORI]`

```bash
OR r/m8, r8
OR r/m16, r16
OR r/m32, r32

OR r/m8, imm8
# OR BYTE PTR DST:[0X01DE719C], 0xFF
OR r/m16, imm16
OR r/m32, imm32

OR r8, m8
OR r16, m16
# OR AX, WORD PTR DST:[0X0109FC8C]
OR r32, m32
```

- `XOR [DST], [ORI]`

```bash
XOR r/m8, r8
XOR r/m16, r16
XOR r/m32, r32

XOR r/m8, imm8
# OR BYTE PTR DST:[0X01DE719C], 0xFF
XOR r/m16, imm16
XOR r/m32, imm32

XOR r8, m8
XOR r16, m16
# XOR AX, WORD PTR DST:[0X0109FC8C]
XOR r32, m32
```

- `NOT [DST]`

```bash
NOT r/m8
NOT r/m16
NOT r/m32
```

## Memory

Memory refers to the processes that are used to acquire, store, retain, and later retrieve information. There are three major processes involved in memory: encoding, storage, and retrieval.

In computing, memory refers to a device that is used to store information for immediate use in a computer or related computer hardware device. It typically refers to semiconductor memory, specifically metal–oxide–semiconductor (MOS) memory, where data is stored within MOS memory cells on a silicon integrated circuit chip. Computer memory operates at a high speed, for example random-access memory (RAM), as a distinction from storage that provides slow-to-access information but offers higher capacities. 

```bash
# memory architecture of a 32-bits computer
Address:        Value(Byte)
0x00000000      0xFF
0x00000001      0xCC
0x00000002      0xDE
...
...
...
...
0xFFFFFFFE      0xCC
0xFFFFFFFF      0xCC
```

Thus, the maximum range of memory is from `0x0` to `0xFFFFFFFF` in a 32-bits machine. So, we can store `FFFFFFFF + 1` bytes information, which is `4G`, which explains that there are 4G physical memory in a 32-bits computer at most.

- `LEA [DST], [ORI]`

```bash
# LEA command is used for getting address of a block of memory.
MOV EAX, 0x0014F2DC
LEA EAX, DWORD PTR DS:[EAX+4]
```

### Stack-based Memory Allocation

Stacks in computing architectures are regions of memory where data is added or removed in a last-in-first-out (LIFO) manner.

In most modern computer systems, each thread has a reserved region of memory referred to as its stack. When a function executes, it may add some of its local state data to the top of the stack; when the function exits it is responsible for removing that data from the stack.

![stack](codehome/src/img/backward/stack.png)

### PUSH and POP

- `PUSH` command

```bash
# PUSH command is used to push data into memory stack.
PUSH r32
PUSH r16
PUSH m16
PUSH m32
PUSH imm8/imm16/imm32

# also the combination of some other commands could have the same function as PUSH
# say EBX serves as the bottom of a stack, and EDX as the top of a stack
# way 1:
MOV DWORD PTR DS:[EDX-4], 0xFFFFFFFF
SUB EDX, 4

# way 2:
SUB EDX, 4
MOV DWORD PTR DS:[EDX], 0xFFFFFFFF

# way 3:
MOV DWORD PTR DS:[EDX-4], 0xFFFFFFFF
LEA EDX, DWORD PTR DS:[EDX-4] # which is same as `SUB EDX, 4`

# way 4:
LEA EDX, DWORD PTR DS:[EDX-4]
MOV DWORD PTR DS:[EDX], 0xFFFFFFFF
```

- `POP` command

```bash
# POP command is used to pop data out of memory stack.
POP r32
POP r16
POP m16
POP m32
POP imm8/imm16/imm32

# again, the combination of other commands have the same function as POP
MOV ECX, DWORD PTR DS:[EDX]
LEA EDX, DWORD PTR DS:[EDX-4]

# we can access data stored in the memory stack by top pointer or bottom one.
# access the first data put in the stack from bottom pointer
MOV EAX, DWORD PTR DS:[EBX-4]

# access the first data put in the stack from top pointer, assuming 4 data in the stack currently
MOV EAX, DWORD PTR DS:[EDX+C]
```

- `PUSHAD` and `POPAD`

`PUSHAD` and `POPAD` are used to push/pop all registers into/out of stack.

## EFLAGS Registers

The FLAGS register is the status register in Intel x86 microprocessors that contains the current state of the processor. This register is 16 bits wide. Its successors, the EFLAGS and RFLAGS registers, are 32 bits and 64 bits wide, respectively. The wider registers retain compatibility with their smaller predecessors.

|Bit#|MASK|Abbreviation|Description|Category|=1|=0|
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 0 | 0x0001 | CF | Carry Flag | Status | Carry | No Carry |
| 1 | 0x0002 |    | Reserved always 1 | |       |          |
| 2 | 0x0004 | PF | Parity Flag | Status | Parity Even | Parity Odd |
| 3 | 0x0008 |    | Reserved 0 | |       |       |
| 4 | 0x0010 | AF | Adjust Flag | Status | Auxiliary Carry | No Auxiliary Carry |
| 5 | 0x0020 |    | Reserved 0 | |       |       |
| 6 | 0x0040 | ZF | Zero Flag | Status | Zero | Not Zero |
| 7 | 0x0080 | SF | Sign Flag | Status | Negative | Positive | 
| 8 | 0x0100 | TF | Trap Flag | Control |      |      |
| 9 | 0x0200 | IF | Interrupt Flag | Control | Enable | Disable |
| 10 | 0x0400 | DF | Direction Flag | Control | -4 | +4 | 
| 11 | 0x0800 | OF | Overflow Flag | Status | Overflow | Not Overflow |
| 12-13 | 0x3000 | IOPL | I/O privilege level alwasy 1 in 8086 or 186 | System |   |   |
| 14 | 0x4000 | NT | Nested task flag alwasy 1 in 8086 or 186 | System |   |   |
| 15 | 0x8000 |   | Reserved, always 1 on 8086 and 186 |  |   |   |

- CF and OF: when the data is unsigned number, we only check CF, when signed number, we only check OF.

- OF: Overflow occurs ONLY when positive plus positive, or negative plus negative. The key is that programmers have to remind of the maximum of positive number and minimum of negative number. For 8-bits system, maximum number is `0x7F` and minimum number is `0x80`.

```bash
# for 8-bits system, OF occurs when 0x7F -> 0x80, CF occurs when 0xFF -> 0x00

# CF = 0, OF = 0
MOV AL, 0x8
ADD AL, 0x8

# CF = 1, OF = 0
MOV AL, 0xFF
ADD AL, 0x2

# CF = 0, OF = 1
MOV AL, 0x7F
ADD AL, 0x2

# CF = 1, OF = 1
MOV AL, 0xFE
ADD AL, 0x80
# or
MOV AL, 0xBF
ADD AL, 0xBF
```

### Related Command

- `ADC`: Add with Carry, `ADC BYTE PTR DS:[0x00FFDC18], 0x2`
- `SBB`: Sub with Borrow, `SBB AL, CL`
- `XCHG`: Exchange, `XCHG DWORD PTR DS:[0x00FFEC28], EAX`
- `MOVS`: Move from Memory to Memory, `MOVS DWORD PTR DS:[0X00FCEE19], DWORD PTR DS:[0X00FDDE22]`, abbreviated as `MOVSD`
- `STOS`: Move AL/AX/EAX to Memory[Addr:EDI], `STOS DWORD PTR ES:[EDI]`, abbreviated as `STOSD`
- `REP`: Repeat operation for [ECX] times, `REP STOS DWORD PTR ES:[EDI]`

*Noting that in `MOVS` and `STOS`, EDI will +4 when DF = 0, will -4 when DF = 1.*

## Control Flow

- JMP command

`JMP` is used to modify EIP (Instruction Pointer).

- CALL command

`Call` serves to call a function, which is same to these instructions,

```bash
PUSH [Addr of Next Instruction]
MOV EIP, [Addr/Register]
```

- RETN command

`RETN` is used to go back to the location where the function is called, which is same to following insturctions,

```bash
POP ESP

# or

LEA ESP, [ESP+4]
MOV EIP, [ESP-4]
```

- CMP R/M, R/M/IMM

`CMP` is accomplished by `SUB` command, but a little different, which will save the result into a register or memory. Instead, `CMP` only changes flag bits.

```bash
# check ZF bit
MOV EAX, 100
MOV ECX, 100
CMP EAX, ECX

# check SF bit
MOV EAX, 100
MOV ECX, 200
CMP EAX, ECX
```

- JCC commands

| Command | Description | EFLAG | Note |
| :----:  |    :----:   | :----:  | :---: |
| JE/JZ |  Jump if Equal/Zero | ZF = 1 | |
| JNE/JNZ | Jump if NOT Equal/Zero | ZF = 0 | |
| JS | Jump if Negative | SF = 1 | |
| JNS | Jump if Positive | SF = 0 | |
| JP/JPE | Jump if # of 1 is Even | PF = 1 | |
| JNP,JPO | Jump if # of 1 is Odd | PF = 0 | |
| JO | Jump if Overflow | OF = 1 | |
| JNO | Jump if NOT Overflow | OF = 0 | |
| JB/JNAE | Jump if Below | CF = 1 | Unsigned |
| JNB/JAE | Jump if NOT Below | CF = 0 | Unsigned |
| JBE | Jump if Below or Equal | CF = 1 or ZF = 0 | Unsigned |
| JNBE/JA | Jump if Above | CF = 0 and ZF = 0 | Unsigned |
| JL/JNGE | Jump if Less | SF != OF | Signed |
| JNL/JGE | Jump if Greater or Equal | SF = OF | Signed |
| JLE/JNG | Jump if Less or Equal | ZF = 1 or SF != OF | Signed |
| JNLE/JG | Jump if greater | ZF = 0 and SF = OF | Signed |

<!-- 
## C Programming

## Hard Coding

## C++ Programming

## Win32 API

## PE Structure -->

<EndMarkdown>