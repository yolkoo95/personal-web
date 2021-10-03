<!-- Insert title here -->
# Directory Management

## Table of Contents
- [Introduction to Linux](#introductiontolinux)
- [General Command Form](#generalcommandform)
- [Linux Files and Directory Management](#linuxfilesanddirectorymanagement)
	- [Common Operation of Directory](#commonoperationofdirectory)
	- [PATH Variable](#pathvariable)
		- [Environment Variables](#environmentvariables)
		- [PATH](#path)
	- [Management of Files](#managementoffiles)
		- [File Operations](#fileoperations)
		- [Get Path of File](#getpathoffile)
		- [Access the Content of Files](#accessthecontentoffiles)
		- [Modify Attributes of Files](#modifyattributesoffiles)
- [Access Control Management](#accesscontrolmanagement)
	- [UMASK](#umask)
	- [Hidden Attributes of Files](#hiddenattributesoffiles)
	- [Special Permission of Files](#specialpermissionoffiles)
		- [Set-user Identification(SUID)](#set-useridentification(suid))
		- [Set-group identification(SGID)](#set-groupidentification(sgid))
		- [Sticky Bit(SBIT)](#stickybit(sbit))
	- [Get the Type of a File](#getthetypeofafile)
- [Search Commands and Files](#searchcommandsandfiles)
	- [Search for Command](#searchforcommand)
	- [Search by Filename](#searchbyfilename)

<TableEndMark>

<!-- Insert content here -->

## Introduction to Linux

Linux is a family of open source Unix-like operating systems based on the Linux kernel, an operating system kernel first released on September 17, 1991, by Linus Torvalds. Linux is typically packaged in a Linux distribution.

Distributions include the Linux kernel and supporting system software and libraries, many of which are provided by the GNU Project. Many Linux distributions use the word "Linux" in their name, but the Free Software Foundation uses the name GNU/Linux to emphasize the importance of GNU software, causing some controversy.

Linux was originally developed for personal computers based on the Intel x86 architecture, but has since been ported to more platforms than any other operating system. Linux also runs on embedded systems, i.e. devices whose operating system is typically built into the firmware and is highly tailored to the system. This includes routers, automation controls, smart home technology.

Linux is one of the most prominent examples of free and open-source software collaboration. The source code may be used, modified and distributed—commercially or non-commercially—by anyone under the terms of its respective licenses, such as the GNU General Public License.

## General Command Form

The form of linux commands is as follow,

```bash
[root@localhost ~]# 
# where,
# root: current user
# localhost: the name of host machine
# ~: home directory of current user
# #: command symbol of superuser
# $: command symbol of common user

# general form of linux commands
[root@localhost ~]$ command [option] [argument]
```

## Linux Files and Directory Management

#### Directory and File Path

The first important conception of file path is **relative path** and **absolute path**, relative path is the path relative to the location where the user is, yet absolute path is the path which starts from `/` (root directory, not the home directory of root `/root`).

```bash
# absolute directory 
[root@localhost ~]$ pwd
/Users/MinzhiQu/Documents/webDevelopment/webApp

# relative directory
[root@localhost ~]$ cd ../../python

# NOTE:
# '.': where i am in
# '..': my parent directory
# '-': where i was in
# '~': where my home is
# '~username': where the home of username is
```

### Common Operation of Directory

- `cd` command
`cd` means *change directory*, which allows us to jump into other directory.

```bash
cd [absolute path / relative path]
```

- `pwd` command
`pwd` means *print name of current/working directory*

```bash
# a useful argument -P, which will print the path of original file, not link file. 
[root@localhost ~]$ cd /var/mail
[root@localhost /var/mail]$ pwd
/var/mail
[root@localhost /var/mail]$ pwd -P
/var/spool/mail
[root@localhost /var/mail]$ ls -ld /var/mail
# /var/mail is a link file which links to /var/spool/mail
lrwxrwxrwx. 1 root root 10 Nov 29  2018 /var/mail -> spool/mail
```

- `mkdir` command
`mkdir` means *make directories*

```bash
 mkdir -[mp] (directory name)
 # where, 
 # -m --mode=MODE: set file mode (as in chmod), not a=rwx - umask
 # -p, --parents: no error if existing, make parent directories as needed

[root@localhost ~]$ mkdir -m 711 test
[root@localhost ~]$ mkdir --mode=711 test1 
[root@localhost ~]$ ls -l
drwx--x--x 2 root    root 4.0K Aug 10 11:31 test
drwx--x--x 2 root    root 4.0K Aug 10 11:32 test1
```

- `rmdir` command
`rmdir` means *remove the DIRECTORY(ies), if they are empty.*

```bash
rmdir [-p] (directory name)
# where,
# -p, --parents: remove  DIRECTORY  and  its  ancestors;
```

### PATH Variable

Before we talk about `$PATH`, let's discuss what Environment Variables are.

#### Environment Variables

Environment variables hold values related to the current environment, like the Operating System or user sessions.

#### PATH

One of the most well-known is called `PATH` on Windows, Linux and Mac OS X. It specifies the directories in which executable programs* are located on the machine that can be started without knowing and typing the whole path to the file on the command line. 

> PATH is an environment variable on Unix-like operating systems, DOS, OS/2, and Microsoft Windows, specifying a set of directories where executable programs are located. In general, each executing process or user session has its own PATH setting.
> - Wikipedia.org

```bash
[root@localhost ~]$ echo $PATH
/bin:/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin     
[root@localhost ~]$ /bin/ls
# which is equal to
[root@localhost ~]$ ls
```

- `$PATH` is different from user to user, so that Linux is able to give different users limited access permission to files.
- DO NOT add `.` (current directory) to `$PATH`.

##### Related Reading
On Linux and Mac OS X, it usually holds all `bin` and `sbin` directories relevant for the current user. On Windows, it contains at least the `C:\Windows` and `C:\Windows\system32` directories — that's why you can run `calc.exe` or `notepad.exe` from the command line or Run dialog.

Environment Variables in Linux are prefixed with a dollar sign `$` such as `$HOME` or `$HOSTNAME`. Many well-known and standard variables are spelled out in capital letters to signify just that. Keep in mind that variable names are case-sensitive, meaning that `$User` and `$USER` are entirely unrelated from the shell's point of view.

Unix derivatives define system wide variables in shell scripts located mostly in the `/etc` folder, but user-specific values may be given to those variables in scripts located in the home folder (e.g., `/etc/profile`, `$HOME/.bash_profile`). The `.profile` file in the home folder is a common place to define user variables.

### Management of Files

#### File Operations

- `ls` command
`ls` means **list directory contents**, lists  information  about  the FILEs (the current directory by default) and sorts entries alphabetically if none of -cftuvSUX nor --sort is specified.

```bash
ls [-adhli] (directory name)
# where,
# -a, --all: do not ignore entries starting with '.'.
# -d, --directory: list directories themselves, not their contents.
# -h, --human-readable: with -l, print sizes in human readable format (e.g., 1K 234M 2G).
# -l: use a long listing format.
# -i, --inode: print the index number of each file.
```

- `cp` command
`cp` command means *copy files and directories*

```bash
cp [-adiprsu] (source) (destination)
cp [options] (source1 source2 source3 ...) (destination)
# where,
# -a, --archive: same as -dR --preserve=all
# -d: same as --no-dereference --preserve=links, copy link file per se.
# -p: same as --preserve=mode,ownership,timestamps, copy the attributes of the file too, used for backup.
# -R, -r, --recursive: copy directories recursively.
# -i, --interactive: prompt before overwrite (overrides a previous -n option)
# -s, --symbolic-link: make symbolic links instead of copying, like `ln -s` command.
# -u, --update: copy only when the SOURCE file is newer than the destination file or when  the destination file is missing
```

- `rm` command
`rm` means *remove files or directories*.

```bash
rm [-fir] (file or directory)
# where,
# -f, --force: ignore nonexistent files and arguments, never prompt.
# -i: prompt before every removal.
# -r, -R, --recursive: remove directories and their contents recursively.
```

- `mv` command
`mv` means *move (rename) files*.

```bash
mv [-fiu] (source) (destination)
mv [options] (source1 source2 source3) (destination)
# where,
# -f, --force: do not prompt before overwriting.
# -i, --interactive: prompt before overwrite.
# -u, --update: move  only when the SOURCE file is newer than the destination file or when the destination file is missing.
```

#### Get Path of File

- `basename` command: return the basename of path
- `dirname` command: return the directory path
which is often used with `pwd`.

```bash
[root@localhost ~]$ basename $(pwd)
[root@localhost ~]$ dirname $(pwd)
```

#### Access the Content of Files

##### Access Directly

- `cat` command
`cat` means *concatenate files and print on the standard output*.

```bash
cat [-AbEnTv] (filename)
# where,
# -A, --show-all: equivalent to -vET.
# -b, --number-nonblank: number nonempty output lines, overrides -n.
# -E, --show-ends: display $ at end of each line. Noting that end notation in Windows is ^M$.
# -n, --number: number all output lines.
# -T, --show-tabs: display TAB characters as '^I'.
# -v, --show-nonprinting: use ^ and M- notation, except for LFD and TAB. 
```

- `tac` command
`tac` means *concatenate and print files in reverse*.


- `nl` command
`nl` means *number lines of files*.

```bash
nl [-bw] (filename)
# -b, --body-numbering=STYLE: use STYLE for numbering body lines.
# `-b a` equals to `cat -n`
# `-b t` equals to `cat -b`, default.
# -w, --number-width=NUMBER: use NUMBER columns for line numbers.

[root@localhost ~]$ nl -w 3 /etc/issue
  1     \S
  2     Kernel \r on an \m
```

##### Advanced Access Method

- `more` command
`more` is *a filter for paging through text one screenful at a time*.

Interactive commands for more are based on `vi`, 

- `h or ?`: display a summary of these commands.
- `RETURN`: display next k lines of text, defaults to 1.
- `q or Q or INTERRUPT`: exit.
- `f`: skip forward k screenfuls of text.
- `b`: skip backwards k screenfuls of text, defaults  to  1.
- `=`: display current line number.
- `/pattern`: search for kth occurrence of regular expression, defaults to 1.
- `:f`: display current file name and line number.

- `less` command, which is similar to more but more common to use.

##### Content Selection

- `head` command
`head` is used to *print  the  first 10 lines of each FILE to standard output*.

```bash
head [-n number] (filename)
# where,
# -n: print the first K lines instead of the first 10;
```

- `tail` command
`tail` is used to *print  the  last  10 lines of each FILE to standard output*.

##### Access to Binary Files

- `od` command
`od` is used to *write an unambiguous representation, octal bytes by default, of FILE to standard output*.

```bash
od [-t TYPE] (filename)
# where,
# -t, --format=TYPE: select output format or formats.
# TYPE:
# a: default format
# c: ASCII character
# d/f/o/x[size]
```

#### Modify Attributes of Files

##### Time Attributes of Files

There are three time attributes in linux file system,

- `mtime`: modification time, which means the time when the content of the file has been modified, default.
- `ctime`: status time, which means the time when the attributes of the file has been changed.
- `atime`: access time, meaning the time when the file has been accessed.

```bash
# default value of --time argument is mtime
[root@localhost ~]$ ls -l /etc/man_db.conf 
-rw-r--r--. 1 root root 5171 Jun 10  2014 /etc/man_db.conf
[root@localhost ~]$ ls -l --time=atime /etc/man_db.conf
-rw-r--r--. 1 root root 5171 Aug 10 03:49 /etc/man_db.conf
[root@localhost ~]$ ls -l --time=ctime /etc/man_db.conf 
-rw-r--r--. 1 root root 5171 Nov 29  2018 /etc/man_db.conf
```

##### Change Time Attributes

- `touch` command
`touch` is used to change file timestamps.

```bash
touch [-acdmt] (filename)
# where,
# -a: change only the access time.
# -c, --no-create: only change the timestamp of the file to current time and do not create any files.
# -d, --date=STRING: parse STRING and use it instead of current time.
# -m: change only the modification time.
# -t STAMP: use [[CC]YY]MMDDhhmm[.ss] instead of current time.

[root@localhost ~]$ touch -d "2 days ago" bashrc
# change timestamp of bashrc to 2020/12/24 12:12, IMPORTANT, ctime will be current time, but mtime and atime will be assigned time.
[root@localhost ~]$ touch -t 2012241212 bashrc
```

## Access Control Management

### UMASK

UMASK in Linux and Unix systems is actually known as User Mask or it is also called User File creation MASK. This is a kind of base permission or *default permission* given when a new file or folder is created in the Linux box. Most of the distribution of Linux gives 022 as default UMASK.

`umask 0022` would make the new mask `0644 (0666-0022=0644)` meaning that group and others have read (no write or execute) permissions. The "extra" digit (the first number = 0), specifies that there are no special modes. If mode begins with a digit it will be interpreted as octal otherwise its meant to be symbolic.

```bash
[root@localhost ~]$ umask
022
[root@localhost ~]$ umask -S
u=rwx,g=rx,o=rx
```

- Note: the maximum number of user permission to file is **666(-rw-rw-rw-)**, and that to directory is **777(-rwxrwxrwx)**. Therefore, given `umask=0022`, when user create a file, the default permission of the file is **(-rw-r\-\-r\-\-)**, and default permission of the directory is **(-rwxr-xr-x)**.

### Hidden Attributes of Files

- `chattr` command
`chattr` is a file system command which is used for changing the attributes of a file in a directory. The primary use of this command is to make several files unable to alter for users other than the superuser. As we know Linux is a multi-user operating system, there exist a chance that a user can delete a file that is of much concern to another user, say the administrator. To avoid such kinds of scenarios, Linux provides ‘chattr‘. In short, ‘chattr’ can make a file immutable, undeletable, only appendable and many more!

```bash
chattr [+-=] [-ai] (filename)
# '+': adds selected attributes to the existing attributes of the files.
# '–' : causes selected attributes to be removed.
# '=': causes selected attributes to be the only attributes that the files have.
# -a: file can only be opened in append mode for writing.
# -i: file cannot be modified (immutable), the only superuser can unset the attribute.
```

- `lsattr` command
`lsattr` is used to see the attributes of files in a directory.

```bash
lsattr [-adR] (filename or directoryname)
# where,
# -a: list all files in directories, including files that start with '.'.
# -d: list directories like other files, rather than listing their contents.
# -R: recursively list attributes of directories and their contents.
# which is similar to 'ls'
```

### Special Permission of Files

There are 3 special permission that are available for executable files and directories. These are :

- SUID permission
- SGID permission
- Sticky bit

#### Set-user Identification(SUID)

```bash
[root@localhost ~]$ ls -lrt /usr/bin/passwd
-rwsr-sr-x. 1 root root 27832 Jun 10  2014 /usr/bin/passwd
```

If you check carefully, you would find the 2 S’s in the permission field. The first s stands for the SUID and the second one stands for SGID.

When a command or script with SUID bit set is run, its effective UID becomes that of the owner of the file, rather than of the user who is running it.

Another good example of SUID is the su command :

```bash
[root@localhost ~]$ ls -l /bin/su
-rwsr-xr-x 1 root root 32184 Aug 17  2018 /bin/su
```

The setuid permission displayed as an “s” in the owner’s execute field.

##### How to set SUID on a file

```bash
[root@localhost ~]$ chmod 4555 [path_to_file]
```

NOTE: If a capital “S” appears in the owner’s execute field, it indicates that the setuid bit is on, and the execute bit “x” for the owner of the file is off or denied.

#### Set-group identification(SGID)

SGID permission is similar to the SUID permission, only difference is – when the script or command with SGID on is run, it runs as if it were a member of the same group in which the file is a member.

```bash
[root@localhost ~]$ ls -l /usr/bin/write 
-rwxr-sr-x 1 root tty 19624 Aug 17  2018 /usr/bin/write
```

The setgid permission displays as an “s” in the group’s execute field.

NOTE: If a lowercase letter “l” appears in the group’s execute field, it indicates that the setgid bit is on, and the execute bit for the group is off or denied.

##### How to Set GUID on a File

```bash
[root@localhost ~]$ chmod 2555 [path_to_file]
```

##### SGID on a Directory

When SGID permission is set on a directory, files created in the directory belong to the group of which the directory is a member.

For example if a user having write permission in the directory creates a file there, that file is a member of the same group as the directory and not the user’s group.

This is very useful in creating shared directories.

##### How to Set SGID on a Directory

```bash
[root@localhost ~]$ chmod g+s [path_to_directory]
```

#### Sticky Bit(SBIT)

The sticky bit is primarily used on shared directories.

- It is useful for shared directories such as `/var/tmp` and `/tmp` because users can create files, read and execute files owned by other users, but are not allowed to remove files owned by other users.
- For example if user bob creates a file named `/tmp/bob`, other user tom can not delete this file even when the `/tmp` directory has permission of 777. If sticky bit is not set then tom can delete `/tmp/bob`, as the `/tmp/bob` file inherits the parent directory permissions.
- root user (Off course!) and owner of the files can remove their own files.

##### Example of Sticky Bit

```bash
[root@localhost ~]$ ls -ld /var/tmp
drwxrwxrwt. 3 root root 4096 Aug  6 23:16 /var/tmp
# T refers to when the execute permissions are off.
# t refers to when the execute permissions are on.
```

##### How to Set Sticky Bit Permission

```bash
[root@localhost ~]$ chmod +t [path_to_directory]
# or 
[root@localhost ~]$ chmod 1777 [path_to_directory]
```

### Get the Type of a File

- `file` command

```bash
[root@localhost ~]$ file ~/.zshrc
.zshrc: ASCII text
```

## Search Commands and Files

### Search for Command

- `which` command
`which` is used to *show the full path of (shell) commands*.

```bash
which [-a] command
# where,
# -a, --all: print all matching executables in PATH, not just the first.

[root@localhost ~]$ which ifconfig
/usr/sbin/ifconfig

# cd is a intergrated command in shell, so which cannot find it
[root@localhost ~]$ which cd
/usr/bin/which: no cd in (/root/anaconda3/bin:/root/anaconda3/condabin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin)
```

NOTE: compared with `whereis`, `which` is able to find alias of a command, and is executed on binary files(command).

### Search by Filename

- `whereis` command
`whereis` locates the binary, source and manual files for the specified command names.

```bash
whereis [-bmsu] (filename)
# where,
# -b: search only for binaries.
# -m: search only for manuals.
# -s: search only for sources.
# -u: only show the command names that have unusual entries.
```

- `locate` command
`locate` allows us to find files by name.

`locate`  reads  one  or  more  databases prepared by `updatedb` and writes file names matching at least one of the PATTERNs to standard output, one per line.

```bash
locate [-ir] patterns
# where,
# -i, --ignore-case: ignore case distinctions when matching patterns.
# -r, --regexp: search  for  a basic regexp, No PATTERNs are allowed if this option is used.
```

Database of `locate` command is at `/var/lib/mlocate/` and `/etc/updatedb.conf` is its configuration file.

- `find` command
`find` searches the directory tree rooted at each given file name by evaluating the given expression from  left  to right,  according  to the rules of precedence, until the outcome is known.

```bash
find [PATH] [option] [expression]

# arguments about time
# -atime, -ctime, -mtime; take -mtime for example,
# -mtime n: search the file that was modified n days ago.
# -mtime -n: search the file that was modified within n days.
# -mtime +n: search the file that was modified longer than n days.

# arguments about users and groups
# -uid/-gid: search by uid/gid.
# -user name: search for files owned by username.
# -group name: search for files belonging to the group.
# -nouser: search for files without a owner.
# -nogroup: search for files without a group.

# arguments about permission and name
# -name: search by name.
# -size [+-]SIZE: search for files bigger or smaller than given SIZE.
# -type TYPE: search by TYPE.
# -perm MODE: search for files with exectly the same mode as MODE. (mode = MODE)
# -perm -MODE: search for files with mode including MODE. (mode > MODE)
# -perm -MODE: search for files with mode included in MODE. (mode < MODE) 

# the following command will operate on the result of executing find command
find / -perm +7000 -exec ls -l {}\;
# where,
# {}: the result of find
# -exec ... \;: keywords, ';' in bash has special meaning, so use '\;' to tell shell that we want ';' itself. 
```

<EndMarkdown>