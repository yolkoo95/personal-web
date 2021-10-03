# Soul Editor of Linux

## Table of Contents
- [Why VIM](#whyvim)
- [Operations](#operations)
	- [Solve Conflict](#solveconflict)
	- [Visual Block](#visualblock)
	- [Multifile Edition](#multifileedition)
	- [Multiview Edition](#multiviewedition)
- [Vim Environment Variables](#vimenvironmentvariables)
- [DOS and Linux](#dosandlinux)

<TableEndMark>

## Why VIM

`Vim` (a contraction of `Vi IMproved`) is a clone, with additions, of Bill Joy's vi text editor program for Unix. It is designed for use both from a command-line interface and as a standalone application in a graphical user interface. 

`Vim` has a `vi` compatibility mode, but when that mode isn't used, Vim has many enhancements over vi. Some of Vim's enhancements include completion, comparison and merging of files (known as vimdiff), a comprehensive integrated help system, extended regular expressions, scripting languages (both native and through alternative scripting interpreters such as Perl, Python, Ruby, Tcl, etc.) including support for plugins, a graphical user interface (known as gvim). All in all, vim is going to be the most popular linux text editor nowadays.

## Operations

Shortcuts of common operation are concluded here,

| Shortcuts | Description |
|:----:|:----:|
| <kbd>←</kbd> or <kbd>h</kbd> | move left by a character |
| <kbd>↓</kbd> or <kbd>j</kbd> | move down by a character |
| <kbd>↑</kbd> or <kbd>k</kbd> | move up by a character |
| <kbd>→</kbd> or <kbd>l</kbd> | move right by a character |
| n + any of <kbd>arrow</kbd> | move somewhere by n characters, eg. 30h |
| <kbd>Ctrl</kbd> + <kbd>f</kbd> | move to next page |
| <kbd>Ctrl</kbd> + <kbd>b</kbd> | back to previous page |
| <kbd>Ctrl</kbd> + <kbd>d</kbd> | move to next half page |
| <kbd>Ctrl</kbd> + <kbd>u</kbd> | back to previous half page |
| <kbd>Ctrl</kbd> + <kbd>f</kbd> | move to next page |
| n + <kbd>space</kbd> | move forward by n characters |
| <kbd>0</kbd> or <kbd>Home</kbd> | move to the first place of a line |
| <kbd>$</kbd> or <kbd>End</kbd> | move to the last place of a line |
| <kbd>G</kbd> | go to the last line of a text |
| n + <kbd>G</kbd> | go to the n-th line of a text |
| <kbd>g</kbd> <kbd>g</kbd> | go to the first line of a text |
| n + <kbd>Enter</kbd> | move to next n line |
| <kbd>/</kbd> + word | look for the string with the keyword 'word' below current line |
| <kbd>?</kbd> + word | look for the string with the keyword 'word' above current line |
| <kbd>n</kbd> | repeat previous searching operation |
| <kbd>N</kbd> | repeat previous searching operation in opposite direction |
| `:n1,n2s/word1/word2/g` | search word1 and replace it with word2 between lines with number n1 or n2 |
| `:1,$s/word1/word2/g` | search word1 and replace it with word2 within the whole text |
| `:1,$s/word1/word2/gc` | compared with command above, system will ask for user's confirmation |
| <kbd>x</kbd> or <kbd>X</kbd> | delete a character forward or backward |
| n + <kbd>d</kbd> <kbd>d</kbd> | delete current line and n-1 following lines |
| <kbd>d</kbd> <kbd>1</kbd> <kbd>G</kbd> | delete lines ranging from current line to the first line |
| <kbd>d</kbd> <kbd>G</kbd> | delete lines ranging from current line to the last line |
| n + <kbd>y</kbd> <kbd>y</kbd> | copy current line and n-1 following lines |
| <kbd>y</kbd> <kbd>1</kbd> <kbd>G</kbd> | copy lines ranging from current line to the first line |
| <kbd>y</kbd> <kbd>G</kbd> | copy lines ranging from current line to the last line |
| <kbd>d</kbd> <kbd>1</kbd> <kbd>G</kbd> | delete lines ranging from current line to the first line |
| <kbd>p</kbd> or <kbd>P</kbd> | paste on the line below current line or above |
| <kbd>u</kbd> | undo last operation |

and file operation,

| Shortcuts | Description |
|:----:|:----:|
| <kbd>:</kbd> <kbd>w</kbd> | write content into the file |
| <kbd>:</kbd> <kbd>w</kbd> <kbd>!</kbd> | for read only file, force to write |
| <kbd>:</kbd> <kbd>q</kbd> | quit from Vim |
| <kbd>:</kbd> <kbd>q!</kbd> | force to quit without saving changes |
| <kbd>w</kbd> <kbd>q</kbd> | write content and quit |
| <kbd>:</kbd> <kbd>w</kbd> (filename) | save as a new file named filename, eg. :w helloworld.md |
| <kbd>:</kbd> <kbd>r</kbd> (filename) | read content of the file into the line below current line |
| `:n1,n2w (filename)` | save the content of the line with number from n1 to n2 as filename |
| <kbd>:</kbd> <kbd>!</kbd> command | execute command in vim editor | 

### Solve Conflict

Let's take an experience.

```bash
[root@localhost ~] vim testfile
# then type in ctrl + z, to put the file into background
[1]  + 13259 suspended  vim testfile

[root@localhost ~] ls -al
-rw-r--r--   1 root root         17 Nov 30 09:11 testfile
-rw-r--r--   1 root root      12288 Nov 30 09:11 .testfile.swp # <== here

# simulate that the machine has been shutdown unexpectedly
# which will cause vim editor to quit abnormally
[root@localhost ~] kill -9 %1
[root@localhost ~] vim testfile

E325: ATTENTION                                                                                
Found a swap file by the name ".testfile.swp"
          owned by: root   dated: Mon Nov 30 09:11:37 2020
         file name: ~root/testfile
          modified: no
         user name: root   host name: iZ2zei99okbo7v4d6fma9eZ
        process ID: 13259 (still running)
While opening file "testfile"
             dated: Mon Nov 30 09:11:11 2020

(1) Another program may be editing the same file.  If this is the case,
    be careful not to end up with two different instances of the same
    file when making changes.  Quit, or continue with caution.
(2) An edit session for this file crashed.
    If this is the case, use ":recover" or "vim -r testfile"
    to recover the changes (see ":help recovery").
    If you did this already, delete the swap file ".testfile.swp"
    to avoid this message.

Swap file ".testfile.swp" already exists!
[O]pen Read-Only, (E)dit anyway, (R)ecover, (Q)uit, (A)bort:
```

There are two senario that will cause this problem in general: 1. more than 1 user open the file in the same time. 2. the file edited is aborted unexpectedly.

Therefore, the right way to do that is to (1) tell your friends who use the file to close the file, (2) find `.filename.swp` and delete it if you don't want save the change that you made before abortion. 

### Visual Block

Visual block operation allows user to select a block they want to manipulate.

| Shortcuts | Description |
|:----:|:----:|
| <kbd>Ctrl</kbd>+<kbd>v</kbd> | activate block selection |
| <kbd>v</kbd> | select by characters |
| <kbd>V</kbd> | select by lines |
| <kbd>y</kbd> | copy content of selected place |
| <kbd>d</kbd> | delete content of selected place |

### Multifile Edition

Open more than one file by `vim file1 file2 file3`

| Shortcuts | Description |
|:----:|:----:|
| <kbd>:</kbd> <kbd>n</kbd> | toggle to next file |
| <kbd>:</kbd> <kbd>N</kbd> | toggle to previous file |
| <kbd>:</kbd> <kbd>files</kbd> | show all opened files |

### Multiview Edition

| Shortcuts | Description |
|:----:|:----:|
| `:sp [filename]` | open a file and split the window into 2 windows |
| <kbd>Ctrl</kbd>+<kbd>w</kbd>+<kbd>↓</kbd> | the cursor will jump to de window below |
| <kbd>Ctrl</kbd>+<kbd>w</kbd>+<kbd>↑</kbd> | the cursor will jump to de window above |
| <kbd>Ctrl</kbd>+<kbd>w</kbd>+<kbd>q</kbd> | quit the window where the cursor is |

## Vim Environment Variables

All settings could be found and configured in `~/.vimrc`.

| Commands | Description |
|:----:|:----:|
| `:set nu` or `set nonu` | turn line number on/off |
| `:set autoindent` | turn autoindent on |
| `:syntax on/off` | turn syntax on/off |
| `:set all` | show all arguments |

## DOS and Linux

DOS and Linux system have different **end symbol**, `^M$` and `$` respectively. there are two useful command to transform the end symbol between DOS and Linux.

```bash
dos2UNIX [-kn] file [newfile]
UNIX2dos [-kn] file [newfile]
# where,
# -k: keep modification time of original file.
# -n: keep origin and output the result to a new file.

[root@localhost ~] dos2UNIX -k -n man.config man.config.linux
```

TIP: `yum install dos2unix` to install the command.

<EndMarkdown>