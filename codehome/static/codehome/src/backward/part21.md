# C++ Seg.2

## Table of Contents
- [New and Delete](#newanddelete)
- [Data Structure](#datastructure)
	- [Vector](#vector)
	- [LinkList](#linklist)
	- [Binary Sort Tree](#binarysorttree)
<TableEndMark>

## New and Delete

- `new`
`new` is a keyword in c++, which has the similar function to `malloc`. The basic syntax is as follows,

```c++
int* pi = new int;
int* pi_with_initialization = new int(5);  // Initialized as 5
int* pi_multi = new int[5];  // create 5 int elements
```

- `delete`
Corresponding to `new`, `delete` is used to free memory that's allocated by `new`.

```c++
delete pi;
delete[] pi_multi;
```

Now the question is how are they different from `malloc` and `free`?

The answer is there is only slight difference that even can be ignored.
To be specific, it will be clear after tracking calling process of these functions.

```bash
# In debug version:
# malloc:
malloc --> nh_malloc_dbg --> _heap_alloc_dbg --> _heap_alloc_base --> HeapAlloc
# new:
new --> _nh_malloc --> _nh_malloc_dbg --> _heap_alloc_dbg --> _heap_alloc_base --> HeapAlloc
# free:
free --> _free_dbg --> _free_base --> HeapFree
# delete:
delete --> free --> _free_dbg --> _free_base --> HeapFree
```

## Data Structure

### Vector

`vector` is a container of c++, which is similar to array yet more powerful than array.

Now let's figure out how a vector works.

```c++
// Vector.h: interface for the Vector class.
#if !defined(AFX_VECTOR_H__3B15E858_AFB2_40D7_AB12_4672708D3060__INCLUDED_)
#define AFX_VECTOR_H__3B15E858_AFB2_40D7_AB12_4672708D3060__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#include <windows.h>
#include <memory.h>
#include <assert.h>

#define SUCCESS 0
#define FAILURE -1
#define MALLOC_ERROR -2
#define INDEX_ERROR -3
#define nullptr NULL

#define OUT

#define INITIAL_SIZE 100
#define INCREMENT 20

template <class T_ELE>
class Vector {
public:
	Vector();
	Vector(DWORD dwSize);
	~Vector();

public:
	DWORD at(DWORD dwIndex, OUT T_ELE* pEle);  // get element according to given index
	DWORD push_back(T_ELE Element);  // insert element into the last of vector 
	T_ELE pop_back();  // delete element in the last of vector
	DWORD insert(DWORD dwIndex, T_ELE Element);  // insert element at given index
	T_ELE erase(DWORD dwIndex);  // delete the element at given index
	DWORD capacity();  // return available space in the vector
	void clear();  // clear all elements in the vector
	BOOL empty();  // check if the vector is empty
	DWORD size();  // return the size of the vector

private:
	BOOL expand();  // expand vector when the container is full

private:
	DWORD m_dwIndex;      // next available index
	DWORD m_dwIncrement;  // the increment when the container is full
	DWORD m_dwLength;     // the length of the container
	DWORD m_dwInitSize;   // initial size of container
	T_ELE* m_pVector;     // the pointer to vector allocated in heap
};

#endif
```

```c++
// Vector.cpp: implementation of the Vector class.
//
//////////////////////////////////////////////////////////////////////

#include "Vector.h"

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

template <class T_ELE>
Vector<T_ELE>::Vector()
:m_dwInitSize(INITIAL_SIZE), m_dwIncrement(INCREMENT) {
	// memory allocation
	T_ELE* pVec = new T_ELE[m_dwInitSize];

	// initialization
	memset(pVec, 0, sizeof(T_ELE) * m_dwInitSize);

	// configuration
	m_pVector = pVec;
	m_dwLength = m_dwInitSize;
	m_dwIndex = 0;
}

template <class T_ELE>
Vector<T_ELE>::Vector(DWORD dwSize)
:m_dwIncrement(INCREMENT) {
	assert(dwSize > 0);
	m_dwInitSize = dwSize;
	
	T_ELE* pVec = new T_ELE[m_dwInitSize];
	memset(pVec, 0, sizeof(T_ELE) * m_dwInitSize);

	m_pVector = pVec;
	m_dwLength = m_dwInitSize;
	m_dwIndex = 0;
}

template <class T_ELE>
Vector<T_ELE>::~Vector() {
	delete[] m_pVector;
	m_pVector = nullptr;
	m_dwLength = 0;
	m_dwIndex = 0;
}

//////////////////////////////////////////////////////////////////////
// Operations
//////////////////////////////////////////////////////////////////////

template <class T_ELE>
DWORD Vector<T_ELE>::at(DWORD dwIndex, OUT T_ELE* pEle) {
	assert(dwIndex >= 0 && dwIndex < m_dwLength);
	pEle = m_pVector + dwIndex;

	return SUCCESS;
}

template <class T_ELE>
DWORD Vector<T_ELE>::push_back(T_ELE Element) {
	if (capacity() <= 0) {
		expand();
	}

	memcpy(m_pVector + m_dwIndex, &Element, sizeof(T_ELE));
	// or m_pVector[m_dwIndex] = Element;

	m_dwIndex++;

	return SUCCESS;
}

template <class T_ELE>
T_ELE Vector<T_ELE>::pop_back() {
	assert(m_dwIndex > 0);
	T_ELE last;
	memcpy(&last, &m_pVector[m_dwIndex - 1], sizeof(T_ELE));
	// or last = m_pVector[m_dwIndex - 1];

	m_dwIndex--;

	return last;
}

template <class T_ELE>
DWORD Vector<T_ELE>::insert(DWORD dwIndex, T_ELE Element) {
	if ((dwIndex < 0) || (dwIndex > m_dwIndex)) {
		return INDEX_ERROR;	
	}

	if (capacity() <= 0) {
		expand();
	}
	
	// move forward
	for (int i = m_dwIndex; i > dwIndex; i--) {
		memcpy(&m_pVector[i], &m_pVector[i-1], sizeof(T_ELE));
		// or m_pVector[i] = m_pVector[i-1];
	}

	memcpy(&m_pVector[dwIndex], &Element, sizeof(T_ELE));
	// or m_pVector[dwIndex] = Element;
	
	m_dwIndex++;

	return SUCCESS;
}

template <class T_ELE>
T_ELE Vector<T_ELE>::erase(DWORD dwIndex) {
	if ((dwIndex < 0) || (dwIndex >= m_dwIndex)) {
		return INDEX_ERROR;	
	}	
	
	m_dwIndex--;

	for (int i = dwIndex; i < m_dwIndex - 1; i++) {
		memcpy(&m_pVector[i], &m_pVector[i+1], sizeof(T_ELE));
		// or m_pVector[i] = m_pVector[i+1];
	}
}

template <class T_ELE>
DWORD Vector<T_ELE>::capacity() {
	return m_dwLength - m_dwIndex;	
}

template <class T_ELE>
void Vector<T_ELE>::clear() {
	m_dwIndex = 0;
}

template <class T_ELE>
BOOL Vector<T_ELE>::empty() {
	return m_dwIndex == 0 ? true : false;
}

template <class T_ELE>
DWORD Vector<T_ELE>::size() {
	return m_dwIndex;
}

template <class T_ELE>
BOOL Vector<T_ELE>::expand() {
	DWORD newLength = m_dwLength + m_dwIncrement;
	T_ELE* pEle = new T_ELE[newLength];

	memset(pEle, 0, sizeof(T_ELE) * newLength);

	// copy elements
	memcpy(pEle, m_pVector, sizeof(T_ELE) * m_dwLength);
	
	if (m_pVector != nullptr) {
		delete[] m_pVector;
	}
	m_pVector = pEle;

	m_dwLength = newLength;

	return true;
}
```

```c++
// main:
#include "Vector.h"
#include "Vector.cpp"

int main(int argc, char* argv[]) {
	Vector<int> myVec(2);
	
	myVec.push_back(1);
	myVec.push_back(2);
	myVec.push_back(3);
	myVec.insert(1, 9);
	myVec.clear();

	return 0;
}
```

Notice that we have to include `*.h` and `*.cpp` for template class, otherwise the compiler will do not know the implementation of class.

For example, in `main` function, we define a vector class `Vector<int> vec`. In the phase of compiling, the assembler will create a class, say `Vector_Int`, according to template class. If the main function only include `*.h` file, it will be confused about how to implement methods of `Vector_Int`.

### LinkList

`linklist` is another builtin container in c++, which has advantages of operation for insert and delete.

The following code gives us an intuition about how a link list works.

```c++
// LinkList.h: interface for the LinkList class.
#if !defined(AFX_LINKLIST_H__59BFA69D_F465_42B7_8733_B409D973AE79__INCLUDED_)
#define AFX_LINKLIST_H__59BFA69D_F465_42B7_8733_B409D973AE79__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#include <windows.h>

#define SUCCESS 1
#define INDEX_ERROR -1
#define LIST_EMPTY_ERROR -2

#define nullptr NULL
#define IN
#define OUT

template <class T_ELE>
class LinkList  
{
public:
	LinkList();
	~LinkList();

public:
	BOOL IsEmpty();  // check if linklist is empty
	void Clear();  // clear all nodes in list
	DWORD GetElement(IN DWORD dwIndex, OUT T_ELE& Element);  // get element by index
	DWORD GetIndex(IN T_ELE& Element);  // get index of given element
	DWORD Insert(IN T_ELE Element);  // insert element after head
	DWORD Insert(IN DWORD dwIndex, IN T_ELE Element);  // insert element at given index
	DWORD Delete(IN DWORD dwIndex);  // delete element at given index
	DWORD GetSize();  // return the size of linklist

private:
	typedef struct _NODE {
		T_ELE key;
		_NODE* next;
	} NODE, *PNODE;

	PNODE getPointerToCurrentNode(DWORD dwIndex);  // get pointer to given node
	PNODE getPointerToPreviousNode(DWORD dwIndex);  // get pointer to the node previous to given node
	PNODE getPointerToNextNode(DWORD dwIndex);  // get pointer to the node after given node

private:
	PNODE m_pList;
	DWORD m_dwLength;
};

#endif // !defined(AFX_LINKLIST_H__59BFA69D_F465_42B7_8733_B409D973AE79__INCLUDED_)
```

```c++
// LinkList.cpp: implementation of the LinkList class.
//
//////////////////////////////////////////////////////////////////////

#include "LinkList.h"
#include <assert.h>

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

template <class T_ELE>
LinkList<T_ELE>::LinkList() 
:m_pList(nullptr), m_dwLength(0) {

}

template <class T_ELE>
LinkList<T_ELE>::~LinkList()
{
	Clear();
	m_pList = nullptr;
}


template <class T_ELE> 
BOOL LinkList<T_ELE>::IsEmpty() {
	if (m_dwLength == 0) {
		return true;
	}
	else {
		return false;
	}
}

template <class T_ELE>
void LinkList<T_ELE>::Clear() {
	if (!IsEmpty()) {
		while (m_dwLength > 0) {
			Delete(0); // delete from the first one to avoid traversing the list
		}
	}
}

template <class T_ELE>
DWORD LinkList<T_ELE>::Delete(IN DWORD dwIndex) {
	if ((dwIndex < 0) || (dwIndex >= m_dwLength)) {
		return INDEX_ERROR;
	}

	if (IsEmpty()) {
		return LIST_EMPTY_ERROR;
	}

	// case 1: only one node left
	if (m_dwLength == 1) {
		delete m_pList;
		m_pList = nullptr;
		m_dwLength--;

		return SUCCESS;
	}

	// case 2: more than one nodes left
	PNODE del_node = nullptr;
	if (dwIndex == 0) {
		del_node = m_pList;
		m_pList = del_node->next;
		delete del_node;
		del_node = nullptr;
	}
	else {
		PNODE pre_node = getPointerToPreviousNode(dwIndex);
		del_node = pre_node->next;
		pre_node->next = del_node->next;

		delete del_node;
		del_node = nullptr;
	}
	m_dwLength--;

	return SUCCESS;
}


template <class T_ELE>
DWORD GetElement(IN DWORD dwIndex, OUT T_ELE& Element) {
	PNODE cur_node = getPointerToCurrentNode(dwIndex);
	memcpy(Element, &cur_node->key, sizeof(T_ELE));

	return SUCCESS;
}

template <class T_ELE>
DWORD LinkList<T_ELE>::GetIndex(IN T_ELE& Element) {
	PNODE pNode = m_pList;
	int index = -1;
	while (pNode != nullptr) {
		index++;
		if (memcmp(&pNode->key, Element, sizeof(T_ELE)) == 0) {
			break;
		}

		pNode = pNode->next;
	}

	return index;
}

template <class T_ELE>
DWORD LinkList<T_ELE>::Insert(IN T_ELE Element) {
	return Insert(0, Element);
}

template <class T_ELE>
DWORD LinkList<T_ELE>::Insert(IN DWORD dwIndex, IN T_ELE Element) {
	if ((dwIndex < 0) || (dwIndex > m_dwLength)) {
		return INDEX_ERROR;
	}

	// initialize a new node
	PNODE node = new NODE;
	memcpy(&node->key, &Element, sizeof(T_ELE));
	node->next = nullptr;
	
	// case 1: insert the first node
	if (m_dwLength == 0) {
		m_pList = node;
		m_dwLength++;
		return SUCCESS;
	}

	// case 2: otherwise,
	if (dwIndex == 0) {
		node->next = m_pList;
		m_pList = node;
	}
	else {
		PNODE pre_node = getPointerToPreviousNode(dwIndex);
		node->next = pre_node->next;
		pre_node->next = node;
	}

	m_dwLength++;

	return SUCCESS;
}

template <class T_ELE> 
DWORD LinkList<T_ELE>::GetSize() {
	return m_dwLength;
}

////////////////////////////////////////////////////////////
//  Private Funcs:
////////////////////////////////////////////////////////////

template <class T_ELE>
LinkList<T_ELE>::PNODE LinkList<T_ELE>::getPointerToCurrentNode(DWORD dwIndex) {
	assert((dwIndex >= 0) && (dwIndex < m_dwLength));

	PNODE pNode = m_pList;
	DWORD index = -1;
	while (pNode != nullptr) {
		index++;
		if (index == dwIndex) {
			break;
		}

		pNode = pNode->next;
	}
	
	return pNode;
}

template <class T_ELE>
LinkList<T_ELE>::PNODE LinkList<T_ELE>::getPointerToPreviousNode(DWORD dwIndex) {
	return getPointerToCurrentNode(dwIndex - 1);
}

template <class T_ELE>
LinkList<T_ELE>::PNODE LinkList<T_ELE>::getPointerToNextNode(DWORD dwIndex) {
	return getPointerToCurrentNode(dwIndex + 1);
}
```

Notice that `PNODE` is defined in the class as private type. Therefore, in `*.cpp` file, we
 have to add space name to it, `LinkList<T_ELE>::PNODE`.

 ### Binary Sort Tree

 Binary Sort Tree (BSTree) has the same structure as binary tree, but it has its own features as follows,

 - The value of all nodes on the left subtree is less than or equal to the value of its root node.
 - The value of all nodes on the right subtree is greater than or equal to the value of its root node.
 - The left and right subtrees are also binary sort trees respectively.

 Following code shows how it works,

 TIPS: the feature of root node is that its parent is itself.

 ```c++
// TreeNode.h: interface for the TreeNode class.

#if !defined(AFX_TREENODE_H__1F343F35_786E_46AC_9B62_D7D1D9B1179C__INCLUDED_)
#define AFX_TREENODE_H__1F343F35_786E_46AC_9B62_D7D1D9B1179C__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#define nullptr NULL

template <typename T>
class TreeNode {
public:
	T element;
	TreeNode<T>* leftChild;
	TreeNode<T>* rightChild;
	TreeNode<T>* parent;
	
	TreeNode();
	TreeNode(const T ele);
	~TreeNode();
	
	// inline function: only open for given T
	friend bool operator==(const TreeNode& lhs, const TreeNode& rhs);
};


#endif // !defined(AFX_TREENODE_H__1F343F35_786E_46AC_9B62_D7D1D9B1179C__INCLUDED_)
 ```

```c++
// TreeNode.cpp: implementation of the TreeNode class.

#include "TreeNode.h"
#include <iostream>

template <typename T>
TreeNode<T>::TreeNode()
{
	leftChild = nullptr;
	rightChild = nullptr;
	parent = nullptr;
}

template <typename T>
TreeNode<T>::TreeNode(const T ele) {
	memcpy(&element, &ele, sizeof(T));
	leftChild = nullptr;
	rightChild = nullptr;
	parent = nullptr;
}

template <typename T>
TreeNode<T>::~TreeNode()
{
	this->leftChild = nullptr;
	this->rightChild = nullptr;
	this->parent = nullptr;
}

// a normal function 
template <typename T>
bool operator==(const TreeNode<T>& lhs, const TreeNode<T>& rhs) {
	return lhs.element == rhs.element;
}
```

Notice that how to overload operator in template class. Here we use inline declaration.

```c++
// BSTree.h: interface for the BSTree class.

#if !defined(AFX_BSTREE_H__D27265E3_49C4_48F7_9D1B_33F78F322A9C__INCLUDED_)
#define AFX_BSTREE_H__D27265E3_49C4_48F7_9D1B_33F78F322A9C__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#include "TreeNode.h"
#include "TreeNode.cpp"
#include <assert.h>
#include <iostream>
#include <windows.h>

template <typename T>
class BSTree {
public:
	BSTree();
	virtual ~BSTree();

	bool IsEmpty();				
	DWORD Insert(T element);				
	void Delete(T element);				
	TreeNode<T>* Search(const T element);	
	
	void InOrderTraverse();				
	void PreOrderTraverse();				
	void PostOrderTraverse();	
	
private:
	TreeNode<T>* getMaxNode(TreeNode<T>* pNode);	
	TreeNode<T>* getMinNode(TreeNode<T>* pNode);			
	TreeNode<T>* searchNode(TreeNode<T>* pNode,T element);		
	DWORD insertNode(T element, TreeNode<T>* pNode);	
	TreeNode<T>* deleteNode(T element, TreeNode<T>* pNode);		
	void clear(TreeNode<T>* pNode);	

	void inOrderTraverse(TreeNode<T>* pNode);				
	void preOrderTraverse(TreeNode<T>* pNode);				
	void postOrderTraverse(TreeNode<T>* pNode);	

private:
	TreeNode<T>* m_pRoot;
	int m_size;
};

#endif // !defined(AFX_BSTREE_H__D27265E3_49C4_48F7_9D1B_33F78F322A9C__INCLUDED_)
```

Notice that we have to include `TreeNode.cpp` since it is a template class.

```c++
// BSTree.cpp: implementation of the BSTree class.

#include "BSTree.h"

template <typename T>
BSTree<T>::BSTree() 
:m_pRoot(nullptr), m_size(0) {

}

template <typename T>
BSTree<T>::~BSTree()
{
	clear(m_pRoot);
	assert(m_size == 0);
}

template <typename T>
TreeNode<T>* BSTree<T>::getMaxNode(TreeNode<T>* pNode) {
	assert(pNode != nullptr);

	if (pNode->rightChild != nullptr) {
		return getMaxNode(pNode->rightChild);
	}

	return pNode;
}

template <typename T>
TreeNode<T>* BSTree<T>::getMinNode(TreeNode<T>* pNode) {
	assert(pNode != nullptr);

	if (pNode->leftChild != nullptr) {
		return getMinNode(pNode->leftChild);
	}

	return pNode;
}

template <typename T>
TreeNode<T>* BSTree<T>::Search(const T element) {
	return searchNode(m_pRoot, element);	
}

template <typename T>
TreeNode<T>* BSTree<T>::searchNode(TreeNode<T>* pNode,T element) {
	assert(pNode != nullptr);
	
	// memcpy: equal return 0, <0 for a < b, >0 for a > b
	if (pNode->element == element) {
		return pNode;
	}
	else if (pNode->element > element) {
		return searchNode(pNode->leftChild, element);
	}
	else {
		return searchNode(pNode->rightChild, element);
	}

	return nullptr;
}	

template <typename T>
DWORD BSTree<T>::Insert(T element) {	
	return insertNode(element, m_pRoot);
}

template <typename T>
DWORD BSTree<T>::insertNode(T element, TreeNode<T>* pNode) {
	// if it is the first node to be inserted
	if (m_size == 0) {
		TreeNode<T>* node = new TreeNode<T>(element);
		node->parent = node;
		m_pRoot = node;
		m_size++;
		return 0;
	}

	// else
	assert(pNode != nullptr);

	if (element <= pNode->element) {
		if (pNode->leftChild == nullptr) {
			TreeNode<T>* newNode = new TreeNode<T>(element);
			newNode->parent = pNode;
			pNode->leftChild = newNode;
			m_size++;
			return 0;
		} 
		else {
			return insertNode(element, pNode->leftChild);
		}
	}
	else {
		if (pNode->rightChild == nullptr) {
			TreeNode<T>* newNode = new TreeNode<T>(element);
			newNode->parent = pNode;
			pNode->rightChild = newNode;
			m_size++;
			return 0;
		}
		else {
			return insertNode(element, pNode->rightChild);
		}
	}

	return 255;
}

template <typename T>
void BSTree<T>::Delete(T element) {
	assert(m_size > 0);
	TreeNode<T>* node = deleteNode(element, m_pRoot);
	if (node == nullptr) {
		std::cout << "Error: No node matched." << std::endl;
	} 
	else {
		delete node;
		node = nullptr;
		std::cout << "The element has been deleted." << std::endl;
	}
}

template <typename T>
TreeNode<T>* BSTree<T>::deleteNode(T element, TreeNode<T>* pNode) {
	assert(pNode != nullptr);
	
	// find matching node
	TreeNode<T>* node = searchNode(pNode, element);
	if (node == nullptr) {
		return nullptr;
	}

	// if this is the only node left in the tree
	if (m_size == 1) {
		m_size--;
		return pNode;
	}
	
	// IMPORTANT: if the node is root node, reshape so that it will  not be the root
	TreeNode<T>* parentNode = node->parent;
	if (parentNode == node) {
		TreeNode<T>* newRoot = getMaxNode(node->leftChild);
		newRoot->parent->rightChild = nullptr;
		newRoot->parent = newRoot;
		newRoot->leftChild = node->leftChild;
		newRoot->rightChild = node;
		node->leftChild = nullptr;
		node->parent = newRoot;
	}

	// reshape nodes whose ancestor is node to be deleted
	parentNode = node->parent; // do NOT forget to update parent;
	bool isLeft = 0;
	bool isRight = 0;
	
	// check left or right child
	if (parentNode->leftChild == node) {
		isLeft = 1;
	}
	else {
		isRight = 1;
	}

	// case 1: no child
	if (isLeft) {
		parentNode->leftChild = nullptr;
		m_size--;
		return node;
	}
	else {
		parentNode->rightChild = nullptr;
		m_size--;
		return node;
	}

	// case 2: one of children exists
	if ((node->leftChild != nullptr) && (node->rightChild == nullptr)) {
		node->leftChild->parent = node->parent;
		if (isLeft) {
			parentNode->leftChild = node->leftChild;
		}
		else {
			parentNode->rightChild = node->leftChild;
		}

		m_size--;
		return node;
	}
	if ((node->leftChild == nullptr) && (node->rightChild != nullptr)) {
		node->rightChild->parent = node->parent;
		if (isLeft) {
			parentNode->leftChild = node->rightChild;
		}
		else {
			parentNode->rightChild = node->rightChild;
		}

		m_size--;
		return node;
	}

	// case 3: both of children exist
	TreeNode<T>* newAncestor = getMaxNode(node->leftChild);
	newAncestor->parent->rightChild = nullptr;
	newAncestor->parent = parentNode;
	newAncestor->leftChild = node->leftChild;
	newAncestor->rightChild = node->rightChild;

	if (isLeft) {
		parentNode->leftChild = newAncestor;
		m_size--;
		return node;
	}
	else {
		parentNode->rightChild = newAncestor;
		m_size--;
		return node;
	}
}

template <typename T>
void BSTree<T>::clear(TreeNode<T>* pNode) {
	assert(pNode != nullptr);

	if (pNode->leftChild != nullptr) {
		clear(pNode->leftChild);
	}
	
	if (pNode->rightChild != nullptr) {
		clear(pNode->rightChild);
	}

	delete pNode;
	pNode = nullptr;
	m_size--;
}

template <typename T>
bool BSTree<T>::IsEmpty() {
	if (m_size == 0) {
		return true;
	}
	else {
		return false;
	}
}

template <typename T>
void BSTree<T>::InOrderTraverse() {
	inOrderTraverse(m_pRoot);	
}

template <typename T>
void BSTree<T>::PreOrderTraverse() {
	preOrderTraverse(m_pRoot);	
}

template <typename T>
void BSTree<T>::PostOrderTraverse() {
	postOrderTraverse(m_pRoot);
}

template <typename T>
void BSTree<T>::inOrderTraverse(TreeNode<T>* pNode) {
	assert(pNode != nullptr);
	
	if (pNode->leftChild != nullptr) {
		inOrderTraverse(pNode->leftChild);
	}
	std::cout << pNode->element << endl;
	if (pNode->rightChild != nullptr) {
		inOrderTraverse(pNode->rightChild);
	}
}

template <typename T>	
void BSTree<T>::preOrderTraverse(TreeNode<T>* pNode) {
	assert(pNode != nullptr);
	
	std::cout << pNode->element << endl;
	if (pNode->leftChild != nullptr) {
		preOrderTraverse(pNode->leftChild);
	}
	if (pNode->rightChild != nullptr) {
		preOrderTraverse(pNode->rightChild);
	}
}

template <typename T>
void BSTree<T>::postOrderTraverse(TreeNode<T>* pNode) {
	assert(pNode != nullptr);
	
	if (pNode->leftChild != nullptr) {
		postOrderTraverse(pNode->leftChild);
	}
	if (pNode->rightChild != nullptr) {
		postOrderTraverse(pNode->rightChild);
	}
	std::cout << pNode->element << endl;
}
```

```c++
// main:
#include <iostream>
#include "BSTree.h"
#include "BSTree.cpp"
using namespace std;

void TEST_BSTree() {
	BSTree<int> tree;

	tree.Insert(12);	
	tree.Insert(8);	
	tree.Insert(5);	
	tree.Insert(9);	
	tree.Insert(17);	
	tree.Insert(15);	
	tree.Insert(13);

	tree.InOrderTraverse();

	tree.Delete(9);
	tree.InOrderTraverse();
}

int main(int argc, char* argv[]) {
	
	TEST_BSTree();

	return 0;
}
```

<EndMarkdown>