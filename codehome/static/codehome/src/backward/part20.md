# C++ Seg.1

## Table of Contents
- [Inheritance](#inheritance)
- [Permission Control](#permissioncontrol)
- [Virtual Function](#virtualfunction)
	- [Virtual Function Table](#virtualfunctiontable)
	- [Call Method](#callmethod)
	- [Print VFT](#printvft)
	- [Inherited VFT](#inheritedvft)
- [Bound](#bound)
	- [Static Bound](#staticbound)
	- [Dynamic Bound](#dynamicbound)
- [Template](#template)
- [Reference](#reference)
- [Friend](#friend)
- [Operation Overload](#operationoverload)

<TableEndMark>

## Inheritance

Inheritance in C++ takes place between classes. In an inheritance relationship, the class being inherited from is called the parent class, base class, or superclass, and the class doing the inheriting is called the child class, derived class, or subclass.

The inheritance follows paradigm like:

```c++
#include <iostream>

class Base {
private:
    int x;
    int y;
}

// an instance of public inheritance
class Successor: public Base {
    int a;
    int b;
}
```

One topic we want to talk about is: can private (discussed later in permission control) members be inherited by successors?

From the point of C++ per se, it seems impossible since the members have been marked as private. However, as a backward programmer, there are no differences between public members and private ones.

```c++
#include <iostream>
#include "myDef.h"
using namespace std;

int main(int argc, char* argv[]) {
	Successor suc;
	
	cout << sizeof(suc) << endl;

	return 0;
}
```

```c++
16
```

## Permission Control

In C++, it includes some marks, for security reason, like private, public, and protect. As we all know, the private members cannot be accessed by programmer by the permission. Yet for architecture programmer, we are able to access them by pointer.

The only difference from public to private is that whether is can be used by other users, or whether is can be served as interface points.

Now let's see how can we access private members by pointers,

```c++
// myDef.h
#include <iostream>

class Base {
public:
	Base();

private:
	int x;
	int y;
};

class Successor: public Base {
public:
	Successor();

private:
	int a;
	int b;
};
```

```c++
// myDef.cpp:
#include "myDef.h"

Base::Base() {
	std::cout << "Initializer of Base: ++++" << std::endl;	
	this->x = 1;
	this->y = 2;
}

Successor::Successor() {
	std::cout << "Initializer of Successor: ++++" << std::endl;
	this->a = 11;
	this->b = 22;
}
```

```c++
#include <iostream>
#include "myDef.h"
using namespace std;

int main(int argc, char* argv[]) {
	Successor suc;
	int* pSuc = (int*)&suc;
	
	cout << sizeof(suc) << endl;
	cout << pSuc[0] << endl;
	cout << pSuc[1] << endl;
	cout << pSuc[2] << endl;
	cout << pSuc[3] << endl;

	return 0;
}
```

```c++
Initializer of Base: ++++
Initializer of Successor: ++++
1       // <-- private member: x
2       // <-- private member: y
11
22
```

## Virtual Function

What's virtual function? Virtual function is the function that marked with `virtual` in a class.

```c++
class class_with_virtual_func {
private:
	int x;

	void func() {

	}

	virtual void vir_func() {

	}
};
```

### Virtual Function Table

What we are concerned first is the differences between normal function and virtual function.

- storage

```c++
// what's the size of the class below and above
class class_with_virtual_func2 {
private:
	int x; 

	void func() {

	}

	virtual void vir_func1() {

	}

	virtual void vir_func2() {

	}
};
```

```c++
int main(int argc, char* argv[]) {
	cout << sizeof(class_with_virtual_func1) << endl;
	cout << sizeof(class_with_virtual_func2) << endl;

	return 0;
}
```

```c++
8
8
```

The answer is 8 bytes -- 4 bytes for variable member x and 4 bytes for the address of virtual function table.

To be specific, let's dig into virtual function table to see what it looks like.

```c++
class class_with_virtual_func {
private:
	int x; 
	int y;

	void func() {

	}

	virtual void vir_func1() {

	}

	virtual void vir_func2() {

	}

public:
	class_with_virtual_func() {
		x = 1;
		y = 2;
	}
};

// given that the structure of the class is:
// base address -> the address of virtual function table
// base addr + 4      x
// base addr + 8      y
//
// addr of vft -> virtual_func1
//                virtual_func2
//                virtual_func3

int main(int argc, char* argv[]) {
	class_with_virtual_func cls;
	class_with_virtual_func* pCls = &cls;

	cout << "The base address of the class is: " << pCls << endl;
	cout << "The address of virtual function table, i.e. the first 4 bytes of the class, is: " << *((int*)pCls + 0) << endl;
	cout << "Visit x by pointer: " << *((int*)pCls + 1) << endl;
	cout << "Visit y by pointer: " << *((int*)pCls + 2) << endl;

	return 0;
}
```

### Call Method

- call

Different from `E8` direct call, it will use `FF` indirect call for virtual function.

```c++
   // call by instance
34:       cls.func();
004011C6 8D 4D F4             lea         ecx,[ebp-0Ch]
004011C9 E8 5F FE FF FF       call        @ILT+40(class_with_virtual_func::func) (0040102d)
35:       cls.vir_func1();
004011CE 8D 4D F4             lea         ecx,[ebp-0Ch]
004011D1 E8 F2 FE FF FF       call        @ILT+195(class_with_virtual_func::vir_func1) (004010c8)

   // call by pointer
38:       pCls->func();
004011D6 8B 4D F0             mov         ecx,dword ptr [ebp-10h]
004011D9 E8 4F FE FF FF       call        @ILT+40(class_with_virtual_func::func) (0040102d)
39:       pCls->vir_func1();
004011DE 8B 4D F0             mov         ecx,dword ptr [ebp-10h]
004011E1 8B 11                mov         edx,dword ptr [ecx]
004011E3 8B F4                mov         esi,esp
004011E5 8B 4D F0             mov         ecx,dword ptr [ebp-10h]
004011E8 FF 12                call        dword ptr [edx]
004011EA 3B F4                cmp         esi,esp
004011EC E8 0F 83 00 00       call        __chkesp (00409500)
40:       pCls->vir_func2();
004011F1 8B 45 F0             mov         eax,dword ptr [ebp-10h]
004011F4 8B 10                mov         edx,dword ptr [eax]
004011F6 8B F4                mov         esi,esp
004011F8 8B 4D F0             mov         ecx,dword ptr [ebp-10h]
004011FB FF 52 04             call        dword ptr [edx+4]
004011FE 3B F4                cmp         esi,esp
00401200 E8 1B 83 00 00       call        __chkesp (00409520)
```

Notice that if the function is called by instance, there is no difference between member function and virtual function. Yet if by pointer, member function will be called directly and the other be called indirectly.

BTW, in assembly code, `edx` saves the address of virtual function table.

### Print VFT

Now let's try to print virtual function table. The class is defined as follows,

```c++
class class_with_virtual_func {
private:
	int x; 
	int y;

	void func() {

	}

	virtual void vir_func1() {

	}

	virtual void vir_func2() {

	}

public:
	class_with_virtual_func() {
		x = 1;
		y = 2;
	}
};
```

We will try to print virtual function list by hand,

```c++
typedef void (*pFunc)(void);

int main(int argc, char* argv[]) {
	class_with_virtual_func cls;
	class_with_virtual_func* pCls = &cls;

	int* vft = (int*)(*((int*)pCls + 0));

	printf("The address of virtual function table: %x\n", vft);
	printf("The address of 1st. virtual function is: %x\n", vft[0]);
	printf("The address of 2nd. virtual function is: %x\n", vft[1]);

	// calling by function pointer
	pFunc pfunc = (pFunc)vft[0];
	pfunc();
	
	pfunc = (pFunc)vft[1];
	pfunc();

	return 0;
}
```

### Inherited VFT

Our next question is if virtual function table will be inherited, and if so, how is it inherited?

- no inheritance

In the case of no inheritance, the structure has been discussed above.

```c++
// instance:  [vars]
//            [funcs]
//            virtual function table
// ---------------------------------
// virtual function table: [virtual functions]
```

- single inheritance without overwriting functions

```c++
class Base {
	virtual void func1() {
		printf("calling func1...\n");
	}
	virtual void func2() {
		printf("calling func2...\n");
	}
};

class Successor: Base {
	virtual void func3() {
		printf("calling func3...\n");
	}
	virtual void func4() {
		printf("calling func4...\n");
	}
};
```

```c++
typedef void (*pFunc)(void);

int main(int argc, char* argv[]) {
	Successor suc;
	Successor* pSuc = &suc;

	int* vft = (int*)(*((int*)pSuc + 0));

	printf("Virtual function table: %x\n", vft);
	
	pFunc pfunc;
	pfunc = (pFunc)vft[0];
	pfunc();
	pfunc = (pFunc)vft[1];
	pfunc();
	pfunc = (pFunc)vft[2];
	pfunc();
	pfunc = (pFunc)vft[3];
	pfunc();

	getchar();

	return 0;
}
```

```c++
Virtual function table: 0x00401380
calling func1...
calling func2...
calling func3...
calling func4...
```

Therefore, in this case, the virtual function table contains those of base class and those of successor class, and it will only keep one virtual function table.

- single inheritance with overwriting functions

```c++
class Base {
	virtual void func1() {
		printf("calling Base::func1...\n");
	}
	virtual void func2() {
		printf("calling Base::func2...\n");
	}
	virtual void func3() {
		printf("calling func3...\n");
	}
};

class Successor: Base {
	virtual void func1() {
		printf("calling Successor::func1...\n");
	}
	virtual void func2() {
		printf("calling Successor::func2...\n");
	}
	virtual void func6() {
		printf("calling func6...\n");
	}
};
```

The `main` function is same as code segment above.

```c++
Virtual function table: 0x00401380
calling Successor::func1...
calling Successor::func2...
calling func3...
calling func6...
```

Notice that the virtual functions of successor will override those of base, and virtual function table only saves the result after overriding. 

- Multi-inheritance without overwriting functions

```c++
class Base1 {
	virtual void func1() {
		printf("calling func1...\n");
	}
	virtual void func2() {
		printf("calling func2...\n");
	}
};

class Base2 {
	virtual void func3() {
		printf("calling func3...\n");
	}
	virtual void func4() {
		printf("calling func4...\n");
	}
};

class Successor: Base1, Base2 {
	virtual void func5() {
		printf("calling func5...\n");
	}
	virtual void func6() {
		printf("calling func6...\n");
	}
};
```

```c++
typedef void (*pFunc)(void);

int main(int argc, char* argv[]) {
	Successor suc;
	Successor* pSuc = &suc;

	int* vft1 = (int*)(*((int*)pSuc + 0));
	int* vft2 = (int*)(*((int*)pSuc + 1));

	printf("Virtual function table[1]: %x\n", vft1);
	printf("Virtual function table[2]: %x\n", vft2);
	
	pFunc pfunc;
	pfunc = (pFunc)vft1[0];
	pfunc();
	pfunc = (pFunc)vft1[1];
	pfunc();
	pfunc = (pFunc)vft1[2];
	pfunc();
	pfunc = (pFunc)vft1[3];
	pfunc();

	printf("\n");
	pfunc = (pFunc)vft2[0];
	pfunc();
	pfunc = (pFunc)vft2[1];
	pfunc();

	getchar();

	return 0;
}
```

```c++
Virtual function table[1]: 0x431078
Virtual function table[2]: 0x43106c
calling func1...
calling func2...
calling func5...
calling func6...

calling func3...
calling func4...
```

Notice that only vft of the first base will be copied into that of successor, and others will be saved as another vft in successor class.

- Multi-inheritance with overwriting functions

```c++
class Base1 {
	virtual void func1() {
		printf("calling Base1::func1...\n");
	}
	virtual void func2() {
		printf("calling func2...\n");
	}
};

class Base2 {
	virtual void func3() {
		printf("calling Base2::func3...\n");
	}
	virtual void func4() {
		printf("calling func4...\n");
	}
};

class Successor: Base1, Base2 {
	virtual void func1() {
		printf("calling Successor::func1...\n");
	}
	virtual void func3() {
		printf("calling Successor::func3...\n");
	}
	virtual void func5() {
		printf("calling func5...\n");
	}
};
```

```c++
typedef void (*pFunc)(void);

int main(int argc, char* argv[]) {
	Successor suc;
	Successor* pSuc = &suc;

	int* vft1 = (int*)(*((int*)pSuc + 0));
	int* vft2 = (int*)(*((int*)pSuc + 1));

	printf("Virtual function table[1]: %x\n", vft1);
	printf("Virtual function table[2]: %x\n", vft2);
	
	pFunc pfunc;
	pfunc = (pFunc)vft1[0];
	pfunc();
	pfunc = (pFunc)vft1[1];
	pfunc();
	pfunc = (pFunc)vft1[2];
	pfunc();

	printf("\n");
	pfunc = (pFunc)vft2[0];
	pfunc();
	pfunc = (pFunc)vft2[1];
	pfunc();

	getchar();

	return 0;
}
```

```c++
Virtual function table[1]: 0x431078
Virtual function table[2]: 0x43106c
calling Successor::func1...
calling func2...
calling func5...

calling Successor::func3...
calling func4...
```

What's similar is that it also keeps two virtual function tables where the first one records the virtual functions of Base1 and Successor. When comes to difference, overwriting function of each table will be replaced by top class.

To sum up, the characteristics of virtual function are:

- it will create more than one virtual function tables in the case of multi-inheritance.
- overwriting functions will be replaced by virtual functions of top class.

## Bound

Bound means unset values have been assigned in a program. There are two kind of bound - static and dynamic one. But first let's see following code.

```c++
class Base {
public:
	int x;

public:
	Base() {
		x = 100;
	}

	void print() {
		cout << "calling Base::print()..." << endl;
	}

	virtual void v_func() {
		cout << "calling Base::v_func()..." << endl;
	}
};

class Successor: public Base {
public:
	int x;

public:
	Successor() {
		x = 200;
	}

	void print() {
		cout << "calling Successor::print()..." << endl; 
	}

	virtual void v_func() {
		cout << "calling Successor::v_func()..." << endl;
	}
};
```

```c++
int main(int argc, char* argv[]) {
	Base bs;
	Successor suc;

	Base* arr[2] = {&bs, &suc};

	for (int i = 0; i < 2; i++) {
		printf("%d\n", arr[i]->x);
		arr[i]->print();
		arr[i]->v_func();
	}

	getchar();

	return 0;
}
```

Guess what's the output.

```c++
100
calling Base::print()...
calling Base::v_func()...
100
calling Base::print()...
calling Successor::v_func()...
```

Notice that base pointer is only able to access functions or members of its own class. Yet for virtual functions, it is able to access virtual functions at different levels, the feature which is called multi-states.

But how does it achieve that function? We have to talk about static bound and dynamic bound.

### Static Bound

Static bound means some unset values are assigned at the stage of compiling.

```c++
41:       Base bs;
004011A8 8D 4D F8             lea         ecx,[ebp-8]
004011AB E8 B4 FE FF FF       call        @ILT+95(Base::Base) (00401064)
42:       Successor suc;
004011B0 8D 4D EC             lea         ecx,[ebp-14h]
004011B3 E8 9D FE FF FF       call        @ILT+80(Successor::Successor) (00401055)

48:           arr[i]->print();
004011F4 8B 45 E0             mov         eax,dword ptr [ebp-20h]
004011F7 8B 4C 85 E4          mov         ecx,dword ptr [ebp+eax*4-1Ch]
004011FB E8 A5 FE FF FF       call        @ILT+160(Base::print) (004010a5)

49:           arr[i]->v_func();
00401200 8B 4D E0             mov         ecx,dword ptr [ebp-20h]
00401203 8B 4C 8D E4          mov         ecx,dword ptr [ebp+ecx*4-1Ch]
00401207 8B 55 E0             mov         edx,dword ptr [ebp-20h]
0040120A 8B 44 95 E4          mov         eax,dword ptr [ebp+edx*4-1Ch]
0040120E 8B 10                mov         edx,dword ptr [eax]
00401210 8B F4                mov         esi,esp
00401212 FF 12                call        dword ptr [edx]
00401214 3B F4                cmp         esi,esp
00401216 E8 45 84 00 00       call        __chkesp (00409660)
```

For lines 41, 42, and 48, these are what we call static bound. The function address has been set at the stage of compiling. Yet for line 49, the function address has not been set, and the register, `edx`, serves as a placeholder for function address, meaning the function is called indirectly, The method what we call dynamic bound.

### Dynamic Bound

As shown above, dynamic bound is achieved by virtual function table. Therefore vft is the key to understand one important feature of c++ -- multi-state.

## Template

Template is another feature of c++, which is created for same code segments with different types. The essence of template is copying code segments.

```c++
// or for template with multi parameters
// template<class T, class V>
template<class T>
T func(T var1, T var2) {
	T var3;

	...
	...

	return var3;
}
```

BTW, the compiler will replace template class with specific class at the stage of compiling. Hence there is no difference in assembly code between a template function and a type-explicit function.


## Reference

- `&` type
Reference type is a type that's similar to `*` type. Yet for security reason, pointers have super power in memory management, however such power could be used abusively. Therefore, `&` type is created in time.

```c++
/*
004010DF 8D 45 FC             lea         eax,[ebp-4]
004010E2 50                   push        eax
004010E3 E8 31 FF FF FF       call        @ILT+20(pass_by_pointer) (00401019)
004010E8 83 C4 04             add         esp,4

41:       *x = 1;
00401058 8B 45 08             mov         eax,dword ptr [ebp+8]
0040105B C7 00 01 00 00 00    mov         dword ptr [eax],1
*/
void pass_by_pointer(int* x) {
	*x = 1;
}

/*
004010EB 8D 4D FC             lea         ecx,[ebp-4]
004010EE 51                   push        ecx
004010EF E8 11 FF FF FF       call        @ILT+0(pass_by_reference) (00401005)
004010F4 83 C4 04             add         esp,4

45:       x = 1;
00401098 8B 45 08             mov         eax,dword ptr [ebp+8]
0040109B C7 00 01 00 00 00    mov         dword ptr [eax],1
*/
void pass_by_reference(int& x) {
	x = 1;
}
```

There is no difference at the level of assembly language. In other word, `&` type can be seen as `const *`.

```c++
int& == const int*
```

Reference type has some limitations:

- it must be initialized when being created.
- it cannot be assigned as other variable.
- reference seems like a pointer which is managed by compiler.

## Friend

`friend` keyword is used to tell compiler that who is my friends. My friends are able to access my private members, such as variables, functions, and so on. Friend function is often used in operation overloading.

## Operation Overload

Operation overload provide us a tool for customizing operation of customer-defined class.

```c++
class Point {
public:
    Point();
    Point(int xc, int yc);
    
    int getX();
    int getY();
    
    std::string toString();
    
    friend bool operator == (Point p1, Point p2);

private:
    int x;
    int y;
};

bool operator == (Point p1, Point p2);

// why != overloaded function is not defined as friend founction of class Point? Because, the implemention of the function does not call private variable of Point directly, which is the same reason to << function;
bool operator != (Point p1, Point p2);
```

```c++
Point::Point() {
    x = 0;
    y = 0;
}

Point::Point(int xc, int yc) {
    x = xc;
    y = yc;
}

int Point::getX() {
    return x;
}

int Point::getY() {
    return y;
}

bool operator == (Point p1, Point p2) {
    return (p1.x == p2.x) && (p1.y == p2.y);
}

bool operator != (Point p1, Point p2) {
    return !(p1 == p2);
}
```

BTW: friend functions cannot be inherited.

<EndMarkdown>