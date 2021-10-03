# Regular Expression and File Formatting

## Table of Contents
- [Regular Expression](#regularexpression)
	- [Overview](#overview)
	- [Preparation](#preparation)
		- [Locale](#locale)
		- [Special Character](#specialcharacter)
		- [Advanced grep](#advancedgrep)
	- [Naive Regular Expression](#naiveregularexpression)
	- [Stream Editor](#streameditor)
	- [Extended RE](#extendedre)
- [File Formatting](#fileformatting)
	- [Formatting Output](#formattingoutput)
	- [Formatting tool](#formattingtool)
	- [File Comparing and Patching](#filecomparingandpatching)

<TableEndMark>

## Regular Expression

### Overview

A regular expression (shortened as regex or regexp) is a sequence of characters that define a search pattern. Usually such patterns are used by string-searching algorithms for "find" or "find and replace". operations on strings, or for input validation. It is a technique developed in theoretical computer science and formal language theory.

Regular expressions are used in search engines, search and replace dialogs of word processors and text editors, in text processing utilities such as sed and AWK and in lexical analysis. Many programming languages provide regex capabilities either built-in or via libraries.

### Preparation

#### Locale

Before we have our experiment, we have to make some configuration so that we are on the same level. Here what we want to emphasize is **locale**. 

```bash
# Different coding system will have a great influence on how we use regular expression

When LANG=C, 0 1 2 3 4 ... A B C D ... Z a b c d ... z
When LANG=zh_CH, 0 1 2 3 4 ... a A b B c C d D ... z Z
When LANG=zh_CH.gb2312, 0 1 2 3 4 ... A a B b C c D d ... Z z

# Thereby, regular expression like '[A-Z]' will generate different results in various locales.
```

#### Special Character

In order to fix that problem, computer scientist came up with a method -- using abstraction.

| Special Character | Description |
| :---: | :---: |
| [:alnum:] | means all alphas in English and digit numbers, 0-9, A-Z, a-z |
| [:alpha:] | means all alphas, A-Z, a-z |
| [:blank:] | means blank space and TAB |
| [:cntrl:] | means control keys on keyboard, CR, LF, TAB, Del, ... |
| [:digit:] | means all digit numbers |
| [:lower:] | all lower case character |
| [:upper:] | all upper case character |
| [:punct:] | means punctuation symbols |
| [:xdigit:] | means all hex digit numbers, 0-9, A-F, a-f |

#### Advanced grep

Here we introduce some advanced function of `grep`,

```bash
grep [-AB, --color=auto] (regular expression) (filename)
# where,
# -A: means after, also print n lines after matching lines.
# -B: means before, also print n lines before matching lines.

# alias grep='grep --color=auto'
[root@localhost ~] dmesg | grep -n 'net'
146:[    0.293385] Initializing cgroup subsys net_cls
151:[    0.298888] Initializing cgroup subsys net_prio
330:[    0.935320] audit: initializing netlink socket (disabled)
340:[    0.987526] SELinux:  Registering netfilter hooks
398:[    1.118371] drop_monitor: Initializing network drop monitor service 
400:[    1.120694] Initializing XFRM netlink socket 
507:[    3.778487] SELinux:  Unregistering netfilter hooks 

[root@localhost ~] dmesg | grep -n -A 2 'net'
146:[    0.293385] Initializing cgroup subsys net_cls 
147-[    0.294475] Initializing cgroup subsys blkio 
148-[    0.295560] Initializing cgroup subsys perf_event
--                                                                                             
151:[    0.298888] Initializing cgroup subsys net_prio 
152-[    0.301229] mce: CPU supports 10 MCE banks
153-[    0.302341] Last level iTLB entries: 4KB 0, 2MB 0, 4MB 0 
...
```

### Naive Regular Expression

| Meta Character | Description |
| :----: | :----: |
| `^word` | matches the starting position within the string |
| `word$` | matches the ending position of the string or the position just before a string-ending newline | 
| `.` | matches any single character, blank character is okay |
| `\` | escape character |
| `*` | matches the preceding element zero or more times |
| `[list]` | a bracket expression, matches a single character that is contained within the brackets |
| `[n1-n2]`| a derivation from `[list]`, ranging from n1 ~ n2 |
| `[^list]` | matches a single character that is NOT contained within the brackets |
| `\{n,m\}` | matches the preceding element at least m and not more than n times |

Noting that `[^list]` and `^[list]` are totally different, the latter means matching any single character in the list, **which must be at the start of the line**.

Now experiment time!

```bash
# EXP 1: search specific pattern
[root@localhost ~] grep -n 'the' regular_expression.txt
8:I cant finish the test.
12:the symbol '*' is represented as start.     
15:You are the best is mean you are the no. 1.
16:The world <Happy> is the same with "glad".
18:google is the best tools for search keyword.

# ignore cases
[root@localhost ~] grep -in 'the' regular_expression.txt
8:I cant finish the test. 
9:Oh! The soup taste good.
12:the symbol '*' is represented as start. 
14:The gd software is a library for drafting programs.
15:You are the best is mean you are the no. 1.
16:The world <Happy> is the same with "glad".          
18:google is the best tools for search keyword.

# EXP 2: use []
[root@localhost ~] grep -n '[^a-z]oo' regular_expression.txt
3:Football game is not use feet only. 
# or
[root@localhost ~] grep -n '[^[:lower:]]oo' regular_expression.txt
3:Football game is not use feet only. 

# EXP 3: ^ and $
[root@localhost ~] grep -n '^the' regular_expression.txt
12:the symbol '*' is represented as start.

# find all lines excluding blank line, for blank lines, it will start end with end symbol '^M$' for DOS and '$' for linux.
[root@localhost ~] grep -nv '^$' regular_expression.txt
1:"Open Source" is a good mechanism to develop programs.
2:apple is my favorite food.                             
3:Football game is not use feet only.                 
4:this dress does not fit me.                
5:However, this dress is about $ 3183 dollars.       
6:GNU is free air not free beer.                         
7:Her hair is very beauty.                                   
8:I cannot finish the test.                    
9:Oh! The soup taste good.                               
10:motorcycle is cheap than car.             
11:This window is clear.                                        
12:the symbol '*' is represented as start.               
13:Oh!  My god!                                                    
14:The gd software is a library for drafting programs. 
15:You are the best is mean you are the no. 1.            
16:The world <Happy> is the same with "glad".                    
17:I like dog.                      
18:google is the best tools for search keyword.      
19:goooooogle yes!                                         
20:go! go! Let us go.                                    

# find lines end with '.'
[root@localhost ~] grep -n '\.$' regular_expression.txt

# EXP 4: . and *
[root@localhost ~] grep -n 'g..d' regular_expression.txt
1:"Open Source" is a good mechanism to develop programs. 
9:Oh! The soup taste good. 
16:The world <Happy> is the same with "glad".

[root@localhost ~] grep -n 'goo*g' regular_expression.txt
18:google is the best tools for search keyword.  
19:goooooogle yes! 

[root@localhost ~] grep -n 'g.*g' regular_expression.txt
1:"Open Source" is a good mechanism to develop programs.
14:The gd software is a library for drafting programs.
18:google is the best tools for search keyword.   
19:goooooogle yes!
20:go! go! Let us go. 

# EXP 5: \{n,m\}
# 'o' will repeat only 2 times
[root@localhost ~] grep -n 'go\{2\}g' regular_expression.txt
18:google is the best tools for search keyword.

# 'o' will repeat no less than 2 times
[root@localhost ~] grep -n 'go\{2,\}g' regular_expression.txt
18:google is the best tools for search keyword.  
19:goooooogle yes!

# 'o' will repeat no less than 2 and no more than 5 times
[root@localhost ~] grep -n 'go\{2,5\}g' regular_expression.txt
18:google is the best tools for search keyword.
```

### Stream Editor

Before discussing extended regular expression, let us learn about a new tool -- stream editor, known as `sed`.

```bash
sed [-nefr] (action sets)
# where,
# -n, --silent: suppress automatic printing of pattern space, processed lines will be printed.
# -e: add the script to the commands to be executed.
# -f: add the contents of script-file to the commands to be executed, script-file include sed command.
# -r: use extended regular expressions in the script.
# -i: edit files in place.
# [n1[,n2]]action: the action will be executed on lines from n1 to n2
# actions:
# a: append text, which has each embedded newline preceded by a backslash.
# c: replace the selected lines with text.
# d: delete pattern space.
# i: insert text, different from 'a', text will be inserted on the line before current line.
# p: print the current pattern space.
# s: attempt to match regexp against the pattern space.


# delete lines
[root@localhost ~] nl /etc/passwd | sed '2,5d'

# backup passwd
[root@localhost ~] nl /etc/passwd > passwd.txt

# add after the second line, if want to insert before, just change 'a' to 'i'
[root@localhost ~] sed '2a drink a cup of tea' passwd.txt
     1  root:x:0:0:root:/root:/bin/zsh
     2  bin:x:1:1:bin:/bin:/sbin/nologin
drink a cup of tea
     3  daemon:x:2:2:daemon:/sbin:/sbin/nologin
     4  adm:x:3:4:adm:/var/adm:/sbin/nologin
...

# change with lines
[root@localhost ~] sed '2,5c hello world \nwelcome to west world' passwd.txt
     1  root:x:0:0:root:/root:/bin/zsh
hello world 
welcome to west world
     6  sync:x:5:0:sync:/sbin:/bin/sync
...

# print desired lines, '-n' prevent from printing original text, which is often used in 'p'
[root@localhost ~] sed -n '2,5p' passwd.txt
     2  bin:x:1:1:bin:/bin:/sbin/nologin
     3  daemon:x:2:2:daemon:/sbin:/sbin/nologin
     4  adm:x:3:4:adm:/var/adm:/sbin/nologin
     5  lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin

[root@localhost ~] sed 's/sbin/yolkoo/g' passwd.txt
     1  root:x:0:0:root:/root:/bin/zsh
     2  bin:x:1:1:bin:/bin:/yolkoo/nologin
     3  daemon:x:2:2:daemon:/yolkoo:/yolkoo/nologin
     4  adm:x:3:4:adm:/var/adm:/yolkoo/nologin
     5  lp:x:4:7:lp:/var/spool/lpd:/yolkoo/nologin
     ...

[root@localhost ~] sed -i 's/\.$/\!/g' regular_expression.txt
# we will find that those lines ending with $ is executed properly, yet with ^M$, improperly.
[root@localhost ~] cat -A regular_express.txt
"Open Source" is a good mechanism to develop programs!$
apple is my favorite food!$
Football game is not use feet only!$
this dress does not fit me!$
However, this dress is about $ 3183 dollars.^M$
GNU is free air not free beer.^M$
Her hair is very beauty.^M$
...
```

### Extended RE

| Meta Character | Description |
| :----: | :----: |
| `+` | the preceding item will be matched one or more times. |
| `?` | include a character or not, eg. `o?` |
| `|` | match string within a or b or c, eg. `gd|good|god` |
| `()` | match strings within the range, eg. `g(oo|o)d` |
| `()+` | combination of `+` and `()`, meaning `()` will be repeated one or more times. eg. AxyzxyzxyzC, `A(xyz)+C`|

*Notice that '!' and '>' are NOT special character in regular expression, though in bash they are.*

## File Formatting

### Formatting Output

`print` allows users to formatting output.

```bash
print [format] (content)
# where,
# formatting arguments:
# \a: warning tone.
# \b: backspace.
# \f: clear screen.
# \n: jump to a new line.
# \r: enter.
# \t: horizontal TAB.
# \v: vertical TAB.
# \xNN: translate hex NN to character.
# like C:
# %ns: s means string, n characters width.
# %ni: i means integer, n integers width.
# %N.nf: f means floating, N for width, n for point length. 8.2f means
# 00000.00, where point takes one bit.

[root@localhost ~] printf "\x45\n"
E

[root@localhost ~] printf '%10s %5i %5i %8.2f \n' $(cat printf.txt | grep -v Name)
     VBird    12    22     1.23
     Brain    22    23    22.11
  Veronica    12    21     2.44
```

### Formatting tool

- `awk`
`awk` is a pattern scanning and processing language, which will divide a line into some fields, some sort of like `cut`, and process them. By default, the delimiter is blank space or TAB.

```bash
# basic syntax of awk
awk 'condition1 {action1} condition2 {action2} ...' (filename)

# take a simple example with no condition, where $0 means this line, $1 means the first field, $2 the second, and so on.
[root@localhost ~] last -n 5
root     pts/0    1.80.152.234     Sat Dec  5 09:13   still logged in 
root     pts/0    1.80.152.234     Fri Dec  4 14:02 - 16:01  (01:59)
root     pts/0    1.80.152.234     Fri Dec  4 13:53 - 13:59  (00:05)
root     pts/0    1.80.165.191     Thu Dec  3 21:53 - 22:25  (00:32)
root     pts/0    1.80.165.191     Thu Dec  3 21:40 - 21:53  (00:12)
[root@localhost ~] last -n 5 | awk '{print $1 "\t" $3}'
root    1.80.152.234
root    1.80.152.234
root    1.80.152.234
root    1.80.165.191
root    1.80.165.191
        
wtmp    Fri # <<==== this line should be ignored.
```

How does `awk` work?

- read a line and assign different segments into fields ($0, $1, $2, ...), where $0 means the line.
- decide whether to go on next move according to conditions.
- process all moves and conditions
- proceed to deal with next line if there is, repeating three steps above. 

How does `awk` know how many cols and rows there are? By its builtin variables.

| Builtin Var | Description |
| :----: | :----: |
| NF | how many fields in a line |
| NR | which row is under processed |
| FS | record delimiter, blank space by default |

```bash
# proceed with our example
[root@localhost ~] last -n 5 | awk '{print $1 "\t lines being processed: " NR "\t columns: " NF}'
root     lines being processed: 1        columns: 10
root     lines being processed: 2        columns: 10
root     lines being processed: 3        columns: 10
root     lines being processed: 4        columns: 10
root     lines being processed: 5        columns: 10
         lines being processed: 6        columns: 0   # <<== blank line
wtmp     lines being processed: 7        columns: 7   # <<== ignore it
```

Now let's talk about conditions by introducing logic operations.

| Operation Symbols | Description |
| :----: | :----: |
| `>` | bigger than |
| `<` | less than |
| `>=` | bigger than or equal to |
| `<=` | less than or equal to |
| `==` | equal to |
| `!=` | not equal to |

```bash
[root@localhost ~] cat /etc/passwd | awk '{FS=":"} $3 < 10 {print $1 "\t " $3}'
# why the first line is improperly displayed
root:x:0:0:root:/root:/bin/zsh   
bin      1
daemon   2
adm      3
lp       4
sync     5
shutdown         6
halt     7
mail     8
```

The reason is that when we read the first line, `awk` has not set its delimiter as ':' but default one blank space until the second step. Using keyword `BEGIN` or `END`, which is builtin keyword of `awk`, is a good way to solve this problem.

```bash
[root@localhost ~] cat /etc/passwd | awk 'BEGIN {FS=":"} $3 < 10 {print $1 "\t " $3}'
root     0   
bin      1
daemon   2
adm      3
lp       4
sync     5
...

# also there is a complex example
[root@localhost ~] cat salary.txt
Name      1st      2nd
Brain     120      240
Bob       200      80

[root@localhost ~] cat salary.txt| awk 'NR==1{printf "%8s %8s %8s %8s\n", $1, $2, $3, "Total"} NR>=2{total = $2 + $3; printf "%8s %8d %8d %10.2f\n", $1, $2, $3, total}'
    Name      1st      2nd    Total
   Brain      120      240     360.00
     Bob      200       80     280.00
```

Notice that 1. the variable in `awk` do not need `${}` 2. more then one command in `{}` should be separated by `;`.

### File Comparing and Patching

- `diff`
`diff` is used to compare files line by line.

```bash
diff [-bBi] (from-file) (to-file)
# where,
# -b: ignore the difference of blank spaces ("about me" is equal to "about    me").
# -B: ignore the difference of blank lines.
# -i: ignore cases.

[root@localhost ~] cp /etc/passwd ./passwd.old
[root@localhost ~] cat passwd.old | sed -e '4d' -e '6c hello world' > passwd.new
[root@localhost ~] diff passwd.old passwd.new
4d3  # <=== 4th row of lhs file has been deleted relative to 3th row of new file
< adm:x:3:4:adm:/var/adm:/sbin/nologin
6c5  # 6th row has been changed
< sync:x:5:0:sync:/sbin:/bin/sync
---
> hello world
```

- `patch`
`patch` is used to apply a diff file to an original, often used for updating files.

First, make a patch file with `diff` command.

```bash
[root@localhost ~] diff -Naur passwd.old passwd.new > passwd.patch
--- passwd.old  2020-12-05 11:02:40.232156981 +0800                                            
+++ passwd.new  2020-12-05 11:02:45.027452008 +0800
@@ -1,9 +1,8 @@  # '-' means old file, '+' means new file
 root:x:0:0:root:/root:/bin/zsh
 bin:x:1:1:bin:/bin:/sbin/nologin
 daemon:x:2:2:daemon:/sbin:/sbin/nologin
-adm:x:3:4:adm:/var/adm:/sbin/nologin  # delete in left file
 lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin
-sync:x:5:0:sync:/sbin:/bin/sync  # delete in left file
+hello world  # add in right file
 shutdown:x:6:0:shutdown:/sbin:/sbin/shutdown
 halt:x:7:0:halt:/sbin:/sbin/halt
 mail:x:8:12:mail:/var/spool/mail:/sbin/nologin
```

How to update with patch file?

```bash
patch [-pN] < patch_file   # <-- for update
patch [-R -pN] < patch_file   # <-- for restore
# where,
# -p: strip the smallest prefix containing num leading slashes from each file name found in the patch file. If in the same directory, -p0.
# -R: means restore.

# update
[root@localhost ~] patch -p0 < passwd.patch
patching file passwd.old
[root@localhost ~] ll passwd.*
-rw-r--r-- 1 root root 1.1K Dec  5 11:02 passwd.new
-rw-r--r-- 1 root root 1.1K Dec  5 11:17 passwd.old
-rw-r--r-- 1 root root  479 Dec  5 11:09 passwd.patch

# restore
[root@localhost ~] patch -p0 -R < passwd.patch
patching file passwd.old
[root@localhost ~] ll passwd.*
-rw-r--r-- 1 root root 1.1K Dec  5 11:02 passwd.new
-rw-r--r-- 1 root root 1.2K Dec  5 11:18 passwd.old
-rw-r--r-- 1 root root  479 Dec  5 11:09 passwd.patch
```

<EndMarkdown>