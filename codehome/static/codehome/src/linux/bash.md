# Bash for Linux

## Table of Contents
- [What is Shell](#whatisshell)
	- [The History of Unix Shell](#thehistoryofunixshell)
		- [Additional Info](#additionalinfo)
- [Shell Variables](#shellvariables)
	- [Environment Variable](#environmentvariable)
		- [env and set](#envandset)
		- [$ and ?](#$and?)
		- [export](#export)
		- [locale](#locale)
	- [Operation on Variables](#operationonvariables)
		- [read and declare](#readanddeclare)
		- [ulimit and dd](#ulimitanddd)
		- [delete and replace](#deleteandreplace)
- [Alias and History](#aliasandhistory)
- [Bash Shell Environment](#bashshellenvironment)
	- [The Order to Find Command](#theordertofindcommand)
	- [Login Information](#logininformation)
	- [Environment Configuration](#environmentconfiguration)
		- [System Env Configuration](#systemenvconfiguration)
		- [User Env Configuration](#userenvconfiguration)
		- [Non-login Shell](#non-loginshell)
		- [Other Configuration](#otherconfiguration)
- [Wildcard and Special Symbol](#wildcardandspecialsymbol)
	- [Wildcard](#wildcard)
	- [Special Symbol](#specialsymbol)
- [Data Redirection](#dataredirection)
	- [Overview](#overview)
		- [Standard Output](#standardoutput)
		- [Standard Input](#standardinput)
- [Logic Expression](#logicexpression)
- [Pipeline Expression](#pipelineexpression)
	- [Cut and Grep](#cutandgrep)
	- [sort wc and uniq](#sortwcanduniq)
	- [Double Redirection](#doubleredirection)
- [Character Operation](#characteroperation)
- [Split and Xargs](#splitandxargs)

<TableEndMark>

## What is Shell

Simply put, the shell is a program that takes commands from the keyboard and gives them to the operating system to perform. In the old days, it was the only user interface available on a Unix-like system such as Linux. Nowadays, we have graphical user interfaces (GUIs) in addition to command line interfaces (CLIs) such as the shell.

In computing, a shell is a computer program which exposes an operating system's services to a human user or other program. It is named a shell because it is the outermost layer around the operating system.

```bash
# the overall layers of a computer

     |____User____|
          |  |
|_Shell, DKE, Application_|  # <--- here 
          |  |
     |___Kernel___|   
          |  |
    |___Hardware___|
```

### The History of Unix Shell

The first Unix shell was the Thompson shell, `sh`, written by Ken Thompson at Bell Labs and distributed with Versions 1 through 6 of Unix, from 1971 to 1975.

But the most widely distributed and influential of the early Unix shells were the Bourne shell and the C shell. Both shells have been used as the coding base and model for many derivative and work-alike shells with extended feature sets.

The `Bourne shell`, sh, was a new Unix shell by Stephen Bourne at Bell Labs. Distributed as the shell for UNIX Version 7 in 1979, it introduced the rest of the basic features considered common to all the Unix shells. Traditionally, the Bourne shell program name is sh and its path in the Unix file system hierarchy is /bin/sh. But a number of compatible work-alikes are also available with various improvements and additional features. On many systems, sh may be a symbolic link or hard link to one of these alternatives:

- `Bourne-Again Shell (Bash)`: written as part of the GNU Project to provide a superset of Bourne Shell functionality. This shell can be found installed and is the default interactive shell for users on most Linux systems.
- `KornShell (ksh)`: written by David Korn based on the Bourne shell sources while working at Bell Labs.
- `Z Shell (zsh)`: a relatively modern shell that is backward compatible with bash. It's the default shell in macOS since 10.15 Catalina.

Yet there is another popular shell called `csh`. The C shell, csh, was modeled on the C programming language, including the control structures and the expression grammar. It was written by Bill Joy as a graduate student at University of California, Berkeley, and was widely distributed with BSD Unix.

So what's legal shell in your machine, just find it out in `/etc/shells`

```bash
[root@localhost ~] vi /etc/shells
/bin/sh                                     
/bin/bash                    
/sbin/nologin    # Wow              
/usr/bin/sh               
/usr/bin/bash               
/usr/sbin/nologin   # Wow again, this two nologin will be introduced later.
/bin/zsh
```

Another question, how the computer know which shell a user should get?
The answer will be found in `/etc/passwd`

```bash
[root@localhost ~] vi /etc/passwd
root:x:0:0:root:/root:/bin/zsh    # <-- the last column shows that
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin
adm:x:3:4:adm:/var/adm:/sbin/nologin
lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin 
```

#### Additional Info

- `type` command
`type` could be used to look for the type of a command. As we all know every command is a executable file.

```bash
type [-ta] (name)
# where,
# -t: will show the type of command as file, alias and builtin.
# -a: find all executable files in ${PATH} and list them.

[root@localhost ~] type ls
ls is an alias for ls --color=tty

# in bash environment
[root@localhost ~] type -t ls
alias    

[root@localhost ~] type -a ls
ls is an alias for ls --color=tty 
ls is /usr/bin/ls
```

BTW, if a command is too long, `\[Enter]` could be used to write command in another line.

```bash
[root@localhost ~] cp hello helloworld westword \
> /root 
```

## Shell Variables

There are two kinds of variables in bash -- `Environment variable` and `User variable`. The one of the significant differences between them is *environment var could be used by other processes* while user var can be used only in current process.

```bash
# get an environment var
[root@localhost ~] echo ${PATH}
/root/anaconda3/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

# set a user var
[root@localhost ~] myVar='HelloWorld'
[root@localhost ~] echo ${myVar}
HelloWorld

# the difference between ' and ''
# ' will interpret the value of a var as a plain string
[root@localhost ~] name='Peter'
[root@localhost ~] greet='Hello ${name}'
[root@localhost ~] echo ${greet}
Hello ${name}
# '' will explain the value of variable in the string
[root@localhost ~] greet="Hello ${name}"
[root@localhost ~] echo ${greet}
Hello Peter

# transfer a user variable into environment
[root@localhost ~] export name
[root@localhost ~] bash  # go into a new process
[root@localhost ~] echo ${name}
Peter
[root@localhost ~] exit  # back to father process

# '\' could be used to transfer the meaning of some special character
[root@localhost ~] greet=How\'s\ the\ weather\ today
[root@localhost ~] echo ${greet}
How's the weather today
```

### Environment Variable

#### env and set

- `env`
`env` command is used to find all environment variables in bash.

```bash
[root@localhost ~] env
USER=root
LOGNAME=root
HOME=/root
PATH=/root/anaconda3/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
MAIL=/var/spool/mail/root
...
```

| Env Var | Description |
|:---:|:---:|
| USER | show identification of user |
| HOME | the home directory of current user |
| SHELL | the shell used by user |
| HISTSIZE | the maximum # of history entries that will be stored |
| MAIL | the mail address of user |
| PATH | the path where to find executable command |
| LANG | which language system that will be used to code |

- `set` and `unset`
`set` is used to get all variables of bash. `unset` is used to unset/free a variable.

```bash
[root@localhost ~] set
GID=0
HISTCHARS='!^#'
HISTCMD=725
HISTCONTROL=ignoredups
HISTFILE=/root/.zsh_history
...
PS1='%(?:%{%}➜ :%{%}➜ ) %{$fg[cyan]%}%c%{$reset_color%} $(git_prompt_info)'
PS2='%_> '
PS3='?# '
...
```

One funny environment is `PS(Prompt Symbol)`, user could define his own
ps according to following rules.

| Arguments | Description |
|:---:|:---:|
| `\d` | show date, eg. Mon Feb 2 |
| `\H` | show full hostname |
| `\t` | show 24-hour time, HH-MM-SS |
| `\A` | show 24-hour time, HH-MM |
| `\u` | show user's name |
| `\v` | show info of bash version |
| `\w` | show full directory path |
| `\W` | show basename of a directory path |
| `\#` | show the number of executed command |
| `\$` | show prompt symbol, $ for users, # for root|

#### $ and ?

`$` and `?` are two special variables. `$` saves PID(Process ID) and `?` stores the status code from last command, **0 for success and others for failure**.

```bash
[root@localhost ~] echo $$
8471
[root@localhost ~] echo ?
0
[root@localhost ~] 12name=hello\ world
-bash: command not found: 12name=hello  
[root@localhost ~] echo ?
127
```

Also `OSTYPE` and `MACHTYPE` saves information about your computer.

```bash
[root@localhost ~] echo ${OSTYPE}
darwin19.0
[root@localhost ~] echo ${MACHTYPE}
x86_64
```

#### export

- `export`
`export` command is used to tranfer a user variable into an environment variable.

```bash
export (variable)

[root@localhost ~] export
HISTCONTROL=ignoredups 
HISTSIZE=50000
HOME=/root 
HOSTNAME=iZ2zei99okbo7v4d6fma9eZ 
...

[root@localhost ~] export name
```

#### locale

To find which language your machine support, `locale` command will help you.

```bash
[root@localhost ~] locale
LANG=en_US.UTF-8
LC_CTYPE="en_US.UTF-8"
LC_NUMERIC="en_US.UTF-8"
LC_TIME="en_US.UTF-8"
LC_COLLATE="en_US.UTF-8"
LC_MONETARY="en_US.UTF-8"
LC_MESSAGES="en_US.UTF-8"
LC_PAPER="en_US.UTF-8"
LC_NAME="en_US.UTF-8"
LC_ADDRESS="en_US.UTF-8"
LC_TELEPHONE="en_US.UTF-8"
LC_MEASUREMENT="en_US.UTF-8"
LC_IDENTIFICATION="en_US.UTF-8"
LC_ALL=
```

Often, we set system language in `LANG` variable.

### Operation on Variables

#### read and declare 

- `read`
`read` command allows to read information from keyboard.

```bash
read [-pt] variable
# where,
# -p: prompt for input.
# -t: time waitting for input from user.
[root@localhost ~] read -p "Please type in your name: " -t 30 name
Please type in your name: Peter
```

- `declare`
`declare` is used to declare the type of a variable.

```bash
declare [-aixr] (variable)
# where,
# -a: declare as an array.
# -i: declare as an integer.
# -x: declare as an environment variable.
# -r: declare as a read-only variable.

[root@localhost ~] declare -ix sum=100+200+300
[root@localhost ~] echo ${sum}
600
```

#### ulimit and dd

- `ulimit`
`ulimit` is used to limit user to use resources abusively.

```bash
ulimit [-afu] (allocation size)
# where,
# -a: show all limit information.
# -f: limit the maximum size of a new file.
# -u: limit the maximum number of process a user could use.

[root@localhost ~] ulimit -a
-t: cpu time (seconds)              unlimited
-f: file size (blocks)              unlimited
-d: data seg size (kbytes)          unlimited
-s: stack size (kbytes)             8192
-c: core file size (blocks)         0
-m: resident set size (kbytes)      unlimited
-u: processes                       7271
-n: file descriptors                65535
-l: locked-in-memory size (kbytes)  64
-v: address space (kbytes)          unlimited
-x: file locks                      unlimited
-i: pending signals                 7271
-q: bytes in POSIX msg queues       819200
-e: max nice                        0
-r: max rt priority                 0
-N 15:                              unlimited

# set the maximum size of new file to be 10240
[root@localhost ~] ulimit -f 10240
[root@localhost ~] dd -if=/dev/zero -of=123 bs=1M count=20
File size limit exceeded  # <= error
```

BTW, `dd` is very useful command, which is used to convert and copy a file.

```bash
[root@localhost ~] dd -if=/dev/zero -of=123 bs=1M count=20
# where,
# -if: input file, read from FILE instead of stdin.
# -of: output file, write to FILE instead of stdout.
# bs: read and write up to 1M bytes at a time.
# count: copy only N input blocks.

# also, dd could be used to backup a filesystem or a file
[root@localhost ~] dd -if=/dev/vda1 -of=/root/vda.img
[root@localhost ~] dd -if=/root/helloworld -of=/root/helloworld.bk

# to restore
[root@localhost ~] dd -if=/root/helloworld.bk -of=/root/helloworld
```

#### delete and replace

There are some special syntax in bash as follows,

| Syntax | Description |
|:---:|:---:|
| ${var#keyword} | search keyword from the beginning and delete until the first matching index |
| ${var##keyword} | search keyword from the beginning and delete until the last matching index |
| ${var%keyword} | search keyword from the end and delete until the first matching index |
| ${var%%keyword} | search keyword from the end and delete until the last matching index |
| ${var/old/new} | search old and replace it with new only one time |
| ${var//old/new} | search old and replace it with new for all matching result |

```bash
[root@localhost ~] mypath=${PATH}
[root@localhost ~] echo ${mypath}
/root/anaconda3/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
[root@localhost ~] echo ${mypath#/*:}
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
[root@localhost ~] echo ${mypath##/*:}
/root/bin
[root@localhost ~] echo ${mypath%:*bin}
/root/anaconda3/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin

# but notice that mypath has not changed, we just echo the result
[root@localhost ~] echo ${mypath}
/root/anaconda3/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
```

And an if-then syntax in bash is as follow, `:-` and `:+` are frequently being used.

| Syntax | str is null | str is '' | str is not '' | 
|:---:|:---:|:---:|:---:|
| var=${str-expr} | var = expr | var = '' | var = ${str} |
| var=${str:-expr} | var = expr | var = expr | var = ${str} |
| var=${str+expr} | var = '' | var = expr | var = expr |
| var=${str:+expr} | var = '' | var = '' | var = expr |

```bash
# in general, var and str are the same variable and the syntax is used like this
[root@localhost ~] username=""
# which means if username is null or '', it will be replaced by root
[root@localhost ~] username=${username:-root}

[root@localhost ~] username="Peter"
# which means the user name will be replaced by root only if username has value(not '')
[root@localhost ~] username=${username:+root}
```

## Alias and History

- `alias` and `unalias`
`alias` is used to set alias to a command.

```bash
[root@localhost ~] alias
l='ls -lah'
l.='ls -d .* --color=auto'
la='ls -lAh'
ll='ls -lh'
ls='ls --color=tty'
lsa='ls -lah'
...

# to set alias
[root@localhost ~] alias rm='rm -i'
```

- `history`
`history` is used to find command history. The maximum # of history record is limited by `HISTSIZE`.

```bash
history [n] # list last n history records
history [-c] # clear all history records
history [-rw] # read and write current history records into histfiles

[root@localhost ~] history
  763  echo ${mypath##/*:}
  764  echo ${mypath#:*bin}
  765  echo ${mypath%:*bin}
  766  alais
  767  alias

[root@localhost ~] history 3
  765  echo ${mypath%:*bin}
  766  alais
  767  alias

[root@localhost ~] history -w
# in default, the history will be written into ~/.bash_history

# execute last command in history
[root@localhost ~] !!
# execute the command with number 3 in history
[root@localhost ~] !3
# execute the command starting with 'gre' recently.
[root@localhost ~] !gre
```

## Bash Shell Environment

### The Order to Find Command

In general, there are many command with the same name, like `ls`. Yet which `ls` is going to be executed when user key in the command.

```bash
[root@localhost ~] type -a echo
echo is an alias for echo -n
echo is a shell builtin
echo is /usr/bin/echo
```

Through `type` command, we will know that the alias will be found first and then builtin, finally the command in `${PATH}`.

### Login Information

Users are allowed to define their login information in `/etc/issue` or `/etc/motd`.

```bash
[root@localhost ~] cat /etc/issue
\S
Kernel \r on an \m
```

| Syntax | Description |
|:----:|:----:|
| `\d` | show host time |
| `\l` | show which client login, tty1~6 |
| `\m` | show hardware version, (i386/i486/i586/...) |
| `\n` | show the network name of the host |
| `\o` | show domain name |
| `\r` | show shell version, (uname -r) |
| `\t` | show local time |
| `\s` | show the name of OS |
| `\v` | show the version of OS |

In addition to `/etc/issue`, there is also `/etc/issue.net`, which is used for remote clients to change their login information.

Furthermore, `/etc/motd` is used to inform everyone who login the host of some information.

```bash
[root@localhost ~] cat /etc/motd

Welcome to Alibaba Cloud Elastic Compute Service !

```

### Environment Configuration

Before discussing the environment configuration of Linux, we have to figure out the difference between two login mode -- `login shell` and `non-login shell`. 

- `login`: requires user to type in username and password so that user could access to the host.
- `non-login`: user could access to the host without password. eg. when creating a new process by `bash`, then you get a non-login shell in that new process.

```bash
[root@localhost ~] bash
# now i'm in a new process with non-login shell
[root@iZ2zeifma9eZ ~]#  
```

Why we talk about that difference? Because these two login mode read environment configuration files in various ways. For `login shell`, it will read two configuration files, `/etc/profile`, and `~/.bash_profile` or `~/.bash_login` or `~/.profile`.

#### System Env Configuration

`/etc/profile` is a system environment configuration file. It includes settings of environment variables (`PATH`, `MAIL`, `USER`, `HISTSIZE` ...) and calls some other configuration files shown below,

- `/etc/input`: if user does not set their own input shortcut, `/etc/profile` will call this file to configure system environment.
- `/etc/profile.d/*.sh`: all shell scripts in `profile.d` will be executed. So if you want to change some environment configuration for all users, you are able to do it here by writing a shell script (eg. alias setting file).
- `/etc/sysconfig/i18n`: sets the language system of Linux.

#### User Env Configuration

After executing system environment configuration files, bash will read users'. It will read one of three files following in given order,

- `~/.bash_profile`
- `~/.bash_login`
- `~/.profile`

Let's look at root's bash_profile,

```bash
# .bash_profile
# Get the aliases and functions
if [ -f ~/.bashrc ]; then 
        . ~/.bashrc
fi 

# User specific environment and startup programs       
PATH=$PATH:$HOME/bin  
export PATH 
```

So for `login shell`, the read flow is like this,

```markdown
/etc/profile ------> ~/.bash_profile -------> Done
     |                        |
     |----> /etc/inputrc      |----- ~/.bashrc
     |                                  |
     |                               /etc/.bashrc
     |----> /etc/profile.d/*.sh  <------|
                  |
                  |----> /etc/sysconfig/i18n
```

TIP: After changing environment configuration files, users should make it come into effect by `source`.

#### Non-login Shell

For Non-login shell, the bash will read only `~/.bashrc`.

```bash
[root@localhost ~] cat ~/.bashrc
# .bashrc

# User specific aliases and functions

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi
```

we will find that it will call `/etc/bashrc`, and then will call `/etc/profile.d/*.sh`. So it will not call `/etc/profile` as shown in read flow figure above.

Often `/etc/bashrc` will do following things,

- setting `umask` according to UID
- setting PS(prompt symbol) according to UID
- calling `/etc/profile.d/*sh`

#### Other Configuration

- `bash_history`: configuration of history, such as `HISTSIZE`.
- `bash_logout`: what will be executed when logging out.
- `stty`: setting tty.

```bash
[root@localhost ~] stty -a 
# ^ means ctrl
speed 38400 baud; rows 30; columns 95; line = 0;
intr = ^C; quit = ^\; erase = ^?; kill = ^U; eof = ^D; eol = M-^?; eol2 = M-^?; swtch = <undef>;                  
start = ^Q; stop = ^S; susp = ^Z; rprnt = ^R; werase = ^W; lnext = ^V; flush = ^O; 
min = 1; time = 0;    

# setting erase to ^h
[root@localhost ~] stty erase ^h
```

## Wildcard and Special Symbol

### Wildcard

| Symbol | Description |
|:---:|:---:|
| * | matches any character zero or more times |
| ? | matches a single character once |
| [] | matches a single character in a range, eg. [abc] or [a-z] |
| [^] | match a single character not in a range |

### Special Symbol

| Symbol | Description |
|:---:|:---:|
| # | comment symbol |
| \ | escape symbol, ESC |
| \| | pipe symbol, used for redirect control flow |
| ; | delimiter of more than one command |
| ~ | user's home directory |
| $ | variable symbol |
| & | job control symbol |
| ! | logic operation NOT | 
| / | directory symbol |
| >, >> | data redirect symbol |
| <, << | data redirect symbol | 
| '' | plain string |
| "" | string with variable transformation |
| `` | command executive symbol, equals to $(...) |
| () | children shell flag symbol |
| {} | command block | 

## Data Redirection

### Overview

Before discussing what the redirection is, we have to know what's the normal data flow.

```bash
# where, std means standard, in/out/err means input/output/error
 ______             _________                ______      ________
|_file_| --stdin--> |_command_| --stdout--> |_file_| or |_device_|
                         |             ______      ________
                         |--stderr--> |_file_| or |_device_|
```

In bash, standard flow has been abstracted as 0 for `standard input`, 1 for `standard output`, and 2 for `standard error`.

#### Standard Output

| Redirection Syntax | Description |
| :----: | :----: |
| 1> | put standard output into a file and override it |
| 1>> | add standard output to the end of a file |
| 2> | put standard error into a file and override it |
| 2>> | add standard error to the end of a file |

*Notice that 1 is often be ignored.*

```bash
# put stdout and stderr into two different files
[root@localhost ~] find /home -name .bashrc > result 2> errorlog

# discard stderr and only show stdout
[root@localhost ~] find /home -name .bashrc 2> /dev/null

# put stdout and stderr into the same file
[root@localhost ~] find /home -name .bashrc > result 2>&1
# or
[root@localhost ~] find /home -name .bashrc &> result

```

#### Standard Input

There is a very interesting syntax allowing user to input from keyboard by `cat > (filename)`, 

```bash
[root@localhost ~] cat > newfile
testing
testfile
# [ctrl] + d to leave
[root@localhost ~] cat newfile
testing
testfile

# << is used to add end flag, so that type in eof is equal to [ctrl] + d
[root@localhost ~] cat > newfile << "eof"
```

*Notice that `cat > (filename)` can be seen as two command, `cat filename` and `> filename`, given that the command is executed from right to left.*

Now how to use a file to input so as to free our hands? The answer is `input redirection`.

```bash
[root@localhost ~] cat > bashrc.bk < ~/.bashrc
[root@localhost ~] ll bashrc.bk ~/.bashrc
-rw-r--r--. 1 root root 176 Dec 29  2013 .bashrc
-rw-r--r--  1 root root 176 Dec  2 17:00 bashrc.bk
```

## Logic Expression

There are three logic Expression in bash - `;`, `&&` and `||`.

| Expression | Description |
| :----: | :----: |
| `cmd1; cmd2` | execute cmd1 and cmd2 in order |
| `cmd1 && cmd2` | execute cmd1 and, if $0 == 0 (means cmd is properly executed), cmd2 is executed |
| `cmd1 || cmd2` | execute cmd1 and, if $0 != 0, cmd2 is executed |

```bash
# if '/root/abs' directory exists, 'touch file1'
[root@localhost ~] ls /root/abs && touch file1

# if '/root/crontab.conf' exists, print 'exist' or print 'not exist'
[root@localhost ~] ls /root/crontab.conf && echo 'exist' || echo 'not exist' 
```

For command block like `cmd1 || cmd2 && cmd3`, `cmd3` will be always executed, take two scenarios,

- `cmd1` is executed improperly, `$0 != 0` so `cmd2` will go on. `cmd2` is likely to be executed properly, thereby `$0 == 0` and `cmd` will be executed. 
- `cmd2` is executed properly, `$0 == 0` so `cmd` will not be executed and `$0` continues to be passed, thereby `cmd3` being executed.
- Of course, in scenario 1, if `cmd2` is problematic, `cmd3` will not be executed, but command block in this way appears to make no sense.

## Pipeline Expression

Pipeline `|` allows users to transfer the standard output into another command.

```bash
cmd1 | cmd2 | cmd3

[root@localhost ~] ls -al /etc | less -
# where,
# - means the output stream from last command.
```

### Cut and Grep

- `cut`
`cut` is used to print selected parts of lines from each FILE to standard output.

```bash
cut -d (delimiter) -f (fields)
cut -c (range)
# where,
# -d: specifies delimiter, TAB in default.
# -f: select only these fields.
# -c: select only these characters.

[root@localhost ~] echo ${PATH}
/root/anaconda3/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
[root@localhost ~] echo ${PATH} | cut -d ':' -f 5
/usr/bin
[root@localhost ~] echo ${PATH} | cut -d ':' -f 3,5
/usr/local/bin:/usr/bin  

[root@localhost ~] export
declare -x HISTCONTROL=ignoredups
declare -x HISTSIZE=50000
declare -x HOME=/root
declare -x HOSTNAME=iZ2zei99okbo7v4d6fma9eZ
declare -x LANG=en_US.UTF-8
declare -x LESS=-R
declare -x LESSOPEN='||/usr/bin/lesspipe.sh %s'
...
[root@localhost ~] export | cut -c 12-
HISTCONTROL=ignoredups
HISTSIZE=50000
HOME=/root
HOSTNAME=iZ2zei99okbo7v4d6fma9eZ
LANG=en_US.UTF-8
LESS=-R
LESSOPEN='||/usr/bin/lesspipe.sh %s'
...
```

- `grep`
`grep` searches the named input FILEs for lines containing a match to  the given PATTERN.

```bash
grep [-acinv --color=auto] (pattern) (filename)
# where,
# -a: processes a binary file as if it were text. 
# -c: counts the time of matching pattern.
# -i: ignores case distinctions.
# -n: show line numbers.
# -v: inverts the sense of matching, to select non-matching lines.

[root@localhost ~] last | grep 'root'
root     pts/0    1.80.165.191     Wed Dec  2 20:26   still logged in
root     pts/0    1.80.165.191     Wed Dec  2 17:00 - 17:05  (00:05) 
root     pts/3    1.80.167.173     Wed Dec  2 16:23 - 19:10  (02:47)
root     pts/2    1.80.167.173     Wed Dec  2 15:38 - 17:50  (02:11)
...
```

### sort wc and uniq

- `sort`
`sort` serves to sort lines of text files.

```bash
sort [-fbMnrutk] (file or stdin)
# where,
# -f: ignore case, fold lower case to upper case characters.
# -b: ignore leading blanks.
# -M: compare by month, (unknown) < 'JAN' < ... < 'DEC'.
# -n: compare according to string numerical value.
# -r: reverse the result of comparisons.
# -u: uniq, output only the first of an equal run.
# -t: delimiter.
# -k: sort via a key/field.

# sort by the third field in numerical order
[root@localhost ~] cat /etc/passwd | sort -t ':' -k 3 -n -
root:x:0:0:root:/root:/bin/zsh 
bin:x:1:1:bin:/bin:/sbin/nologin 
daemon:x:2:2:daemon:/sbin:/sbin/nologin
adm:x:3:4:adm:/var/adm:/sbin/nologin
lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin
sync:x:5:0:sync:/sbin:/bin/sync     
shutdown:x:6:0:shutdown:/sbin:/sbin/shutdown
halt:x:7:0:halt:/sbin:/sbin/halt 
mail:x:8:12:mail:/var/spool/mail:/sbin/nologin 

# find who login host, noting that leading blank line and line with 'wtmp' is useless and generated by `last`, thereby we use grep to get rid of them
[root@localhost ~] last | cut -d ' ' -f1 | sort -u | grep '[a-zA-Z]' | grep -v 'wtmp'
reboot
root
```

- `uniq`
`uniq` is to report or omit repeated lines.

```bash
uniq [-ic]
# where,
# -i: ignore case.
# -c: count time of repetition.

[root@localhost ~] last | cut -d ' ' -f1 | sort -u
# or
[root@localhost ~] last | cut -d ' ' -f1 | sort - | uniq -
```

- `wc`
`wc` stands for word counter, prints newline, word, and byte counts for each file.

```bash
wc [-lwc]
# where,
# -l: print the newline counts.
# -w: print the word counts.
# -c: print the byte counts. If a char is a byte, it also can be seen as character counts.

[root@localhost ~] last | cut -d ' ' -f1 | sort -u | grep '[a-zA-Z]' | grep -v 'wtmp' | wc -l
2
```

### Double Redirection

- `tee`
`tee` is going to read from standard input and write to standard output and files.

```bash
# double data flow
Standard Input  ---->  tee  ----> Screen(Standard Output)
                        |
                        |-------> File

```

```bash
tee [-a] (file)
# where,
# -a: append to the given FILEs, do not overwrite.

# not only print the content of `/home` on screen, but backup into home.log file.
[root@localhost ~] ls -l /home | tee ~/home.log | more
total 8
drwx------ 2 ftpuser ftpuser 4096 Aug  6 23:07 ftpuser
drwx------ 2 ftpUser ftpUser 4096 Aug  7 10:15 ftpUser
```

## Character Operation

- `tr`
`tr` is used to translate or delete characters.

```bash
tr [-ds] (SET1 ...) (stdin)
# where,
# -d: delete strings that match pattern in stdin
# -s: replace each input sequence of a repeated character that is  listed in SET1

# replace lower case into upper case
[root@localhost ~] last | tr '[a-z]' '[A-Z]'
ROOT     PTS/0    1.80.165.191     THU DEC  3 09:10   STILL LOGGED IN
ROOT     PTS/0    1.80.165.191     WED DEC  2 20:26 - 21:05  (00:39)
...

# delete ':' of stdin
[root@localhost ~] cat /etc/passwd  | tr -d ':'
rootx00root/root/bin/zsh
binx11bin/bin/sbin/nologin
daemonx22daemon/sbin/sbin/nologin
...

# transfer DOS delimiter to linux delimiter
[root@localhost ~] unix2dos passwd.dos
[root@localhost ~] cat -A passwd.dos
root:x:0:0:root:/root:/bin/zsh^M$
bin:x:1:1:bin:/bin:/sbin/nologin^M$
...
# '/r' means DOS delimiter
[root@localhost ~] cat /root/passwd.dos | tr -d '\r' > /root/passwd.linux
[root@localhost ~] cat passwd.linux
root:x:0:0:root:/root:/bin/zsh
bin:x:1:1:bin:/bin:/sbin/nologin
...
```

- `col`
`col` is to filter reverse line feeds from input. The common use of `col` is *to transfer TAB to SPACE and to transfer man page into plain text for accessing conveniently*.

```bash
col [-xb] (stdin)
# where,
# -x: outputs multiple spaces instead of tabs.
# -b: do not output any backspaces, printing only the last character written to each column position.

# ^I means TAB
[root@localhost ~] cat -A /etc/man.config
...
#$
#MANDATORY_MANPATH ^I^I^I/usr/src/pvm3/man$
#$
MANDATORY_MANPATH^I^I^I/usr/man$
MANDATORY_MANPATH^I^I^I/usr/share/man$
...
[root@localhost ~] cat /etc/man.config | col -x | cat -A > man.config.with.space
# the TAB has been transferred to space
[root@localhost ~] cat man.config.with.space
...
#$$
#MANDATORY_MANPATH                      /usr/src/pvm3/man$$
#$$
MANDATORY_MANPATH                       /usr/man$$
MANDATORY_MANPATH                       /usr/share/man$$
...

# save manpage as plain text for looking
[root@localhost ~] man ls | col -b > /root/ls.man
```

- `join`
`join` join lines of two files on a common field.

```bash
join [-ti12] (file1) (file2)
# where,
# -t: specifies delimiter.
# -i: ignore cases.
# -1: join on this FIELD of file1.
# -2: join on this FIELD of file2.

[root@localhost ~] head -n 3 /etc/passwd /etc/group
==> /etc/passwd <== 
root:x:0:0:root:/root:/bin/zsh    
bin:x:1:1:bin:/bin:/sbin/nologin               
daemon:x:2:2:daemon:/sbin:/sbin/nologin  

==> /etc/group <==                
root:x:0:                               
bin:x:1:                                        
daemon:x:2: 

# join two file in GID
[root@localhost ~] join -t ':' -1 4 /etc/passwd -2 3 /etc/group
0:root:x:0:root:/root:/bin/zsh:root:x:
1:bin:x:1:bin:/bin:/sbin/nologin:bin:x:
2:daemon:x:2:daemon:/sbin:/sbin/nologin:daemon:x:
...
```

- `paste`
`paste` is going to write lines consisting of the sequentially corresponding lines from each FILE.

```bash
paste [-d] (file1) (file2)
# where,
# -d: delimiter, TAB by default. Delimiter can be only one character or escape code like '\t'.
[root@localhost ~] paste -d ':' /etc/passwd /etc/group | head -n 3
bin:x:1:1:bin:/bin:/sbin/nologin        bin:*:17632:0:99999:7:::
daemon:x:2:2:daemon:/sbin:/sbin/nologin daemon:*:17632:0:99999:7:::
adm:x:3:4:adm:/var/adm:/sbin/nologin    adm:*:17632:0:99999:7:::
```

- `expand`
`expand` is used to convert tabs to spaces, which has the same function with `col -x`.

```bash
expand [-t] (file)
# where,
# -t: have tabs NUMBER characters apart, not 8.

[root@localhost ~] grep '^MANPATH' /etc/man.config | head -n 3 | \
> expand -t 4 - | cat -A
MANPATH_MAP /bin            /usr/share/man$
MANPATH_MAP /usr/bin        /usr/share/man$
MANPATH_MAP /sbin           /usr/share/man$
```

## Split and Xargs

- `split`
`split` is used to split a file into smaller ones.

```bash
split [-bl] (file) (PREFIX)
# where,
# -b: put SIZE bytes per output file.
# -l: put NUMBER lines per output file.

[root@localhost ~] ll /root/etc.tar.gz
-rw-r--r-- 1 root root 9.4M Nov 29 08:47 etc.tar.gz
# noting that unit of -b is k/M, like 100k, 3M
[root@localhost ~] split -b 3M /root/etc.tar.gz etc.tar.gz.sp
[root@localhost ~] ll etc.tar.gz.*
-rw-r--r-- 1 root root 3.0M Dec  3 15:00 etc.tar.gz.spaa
-rw-r--r-- 1 root root 3.0M Dec  3 15:00 etc.tar.gz.spab
-rw-r--r-- 1 root root 3.0M Dec  3 15:00 etc.tar.gz.spac
-rw-r--r-- 1 root root 399K Dec  3 15:00 etc.tar.gz.spad

# restore to a full file
[root@localhost ~] cat etc.tar.gz.* > etc.tar.gz.bk
[root@localhost ~] ll etc.tar.gz.bk
-rw-r--r-- 1 root root 9.4M Dec  3 15:02 etc.tar.gz.bk

# also we could split file according to lines, where '-' means stdin
[root@localhost ~] ls -al / | split -l 10 - lsroot
[root@localhost ~] ll lsroot*
-rw-r--r-- 1 root root 477 Dec  3 15:05 lsrootaa
-rw-r--r-- 1 root root 504 Dec  3 15:05 lsrootab
-rw-r--r-- 1 root root 144 Dec  3 15:05 lsrootac
```

- `xargs`
`xargs` is used to build and execute command lines from standard input.

```bash
xargs [-0epn] (command)
# where,
# -0: Input items are terminated by a null character instead of by whitespace, and the quotes and backslash are not special.
# -e: sets a eof flag by user.
# -p: prompts the user about whether to run each command line and read a line from terminal.
# -n: specifies how many arguments the command need when being executed.

# get information of the first 3 users in /etc/passwd
[root@localhost ~] cut -d ':' -f1 /etc/passwd | head -n 3 | xargs finger
Login: root                             Name: root
Directory: /root                        Shell: /bin/zsh
On since Thu Dec  3 15:10 (CST) on pts/0 from 1.80.165.191 6 seconds idle
No mail.
No Plan.

Login: bin                              Name: bin
Directory: /bin                         Shell: /sbin/nologin
Never logged in.
No mail.
No Plan.
...

# executing with promting from user
[root@localhost ~] cut -d ':' -f1 /etc/passwd | head -n 3 | xargs -p finger
finger root bin daemon ?...

# get information of all users in /etc/passwd, but list 5 a time
[root@localhost ~] cut -d ':' -f1 /etc/passwd | xargs -p -n 5 finger
finger root bin daemon adm lp ?...
....
finger sync shutdown halt mail operator ?...
....

# set end flag, list until matching 'ftp' as an argument
[root@localhost ~] cut -d ':' -f1 /etc/passwd | xargs -p -e'ftp' finger
```

The IDEA is that `xargs` give us a way to use pipe syntax for those command not able to do that. For example, `ls` does not support pipe syntax, however,

```bash
[root@localhost ~] find /sbin -perm +7000 | ls -l
# However, command above is equal to run `ls -l .`, since `ls` does not support pipe syntax.

# So we can fix it by `xargs`, to transfer stdin to args of following command.
[root@localhost ~] find /sbin -perm +7000 | xargs ls -l
```

<EndMarkdown>