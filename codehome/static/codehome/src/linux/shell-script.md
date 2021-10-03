# Shell Script

## Table of Contents
- [Preview](#preview)
- [Basics](#basics)
	- [The First Script](#thefirstscript)
	- [Variables and Interaction](#variablesandinteraction)
	- [Script Execution](#scriptexecution)
- [Control Flow](#controlflow)
	- [Test Command](#testcommand)
	- [Default Variables](#defaultvariables)
	- [If-Then Clause](#if-thenclause)
	- [Case-Esac Clause](#case-esacclause)
- [Function](#function)
- [Loop](#loop)
	- [While Loop](#whileloop)
		- [While-Do-Done](#while-do-done)
		- [Until-Do-Done](#until-do-done)
	- [For Loop](#forloop)
		- [For-Do-Done](#for-do-done)
		- [C-like For-Loop](#c-likefor-loop)
- [Debug](#debug)

<TableEndMark>

## Preview

This tutorial is written to help people understand some of the basics of shell script programming (aka shell scripting), and hopefully to introduce some of the possibilities of simple but powerful programming available under the Bourne shell.

> No programming language is perfect. There is not even a single best language; there are only languages well suited or perhaps poorly suited for particular purposes.
> - Herbert Mayer

Writing shell scripts is not hard to learn, since the scripts can be built in bite-sized sections and there is only a fairly small set of shell-specific operators and options to learn. The syntax is simple and straightforward, similar to that of invoking and chaining together utilities at the command line, and there are only a few "rules" to learn. Most short scripts work right the first time, and debugging even the longer ones is straightforward.

Shell scripting hearkens back to the classic UNIX philosophy of breaking complex projects into simpler subtasks, of chaining together components and utilities. Many consider this a better, or at least more esthetically pleasing approach to problem solving than using one of the new generation of high powered all-in-one languages, such as Perl, which attempt to be all things to all people, but at the cost of forcing you to alter your thinking processes to fit the tool.

## Basics

### The First Script

Let's introduce shell script with `helloWorld.sh`, the first program of all computer languages.

```shell
#!/bin/bash
# Program:
#   This is a bash version of "Hello World"
# History:
#   2020/12/07 Minzhi First Release
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

echo -e "Hello World! \n"

exit 0
```

```bash
[root@localhost ~] touch helloWorld.sh
# note that to make a file executable, you must set the eXecutable bit, and for a shell script, the Readable bit must also be set:
[root@localhost ~] chmod +x helloWorld.sh
[root@localhost ~] bash ./helloWorld.sh
Hello World!

```

The first line `#!/bin/bash` tells system the user should use bash to execute this script, which is super IMPORTANT. Some comments following are also significant for programmer to maintain their scripts. In the last line, `exit 0`, `exit` will return a flag value to tell the system that the status of execution, 0 for "Okay, no problem" and others for "Alas, something wrong goes with it".

There are a number of factors which can go into good, clean, quick, shell scripts.

- Formatting: the most important criteria for any code must be a clear, readable layout. This is true for all languages, but again where the major languages are supported by extensive IDEs, many shell scripts are written in far less forgiving editors, so the onus is on the scripter to ensure that code is well presented. Badly formatted code is so much harder to maintain than well-formatted code.
- Efficiency: A clear layout makes the difference between a shell script appearing as "black magic" and one which is easily maintained and understood. You may be forgiven for thinking that with a simple script, this is not too significant a problem, but two things here are worth bearing in mind.
    - Feature Creep: a simple script will - more often than anticipated - grow into a large, complex one.
    - Maintainability: if nobody else can understand how it works, you may be stuck with maintaining it yourself for the rest of your life!

### Variables and Interaction

`read` allows user to pass a value to a variable by keyboard.

```shell
#!/bin/bash
# Program:
#   This is test script for interaction.
# History:
#   2020/12/07 Minzhi First Release
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

read -p "Please input your favorite animal: " animal
echo -e "\nYour favorite is ${animal}"

exit 0
```

```bash
[root@localhost ~] bash ./animal.sh
Please input your favorite animal: cat   

Your favorite is cat
```

Now let's use variable to do more powerful things.

```shell
#!/bin/bash
# Program:
#   Program creates three files, which named by user's input.
# History:
#   2020/12/07 Minzhi First Release
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

echo -e "This script will use 'touch' to create 3 files with consistent dates."
read -p "Please input your filename: " filename

filename=${filename:-"defaultName"}

file1=${filename}$(date --date='2 days ago' +%Y%m%d)
file2=${filename}$(date --date='1 days ago' +%Y%m%d)
file3=${filename}$(date +%Y%m%d)

touch "$file1"
touch "$file2"
touch "$file3"

exit 0
```

```bash
[root@localhost ~] bash ./file.sh
This script will use 'touch' to create 3 files with consistent dates.
Please input your filename: hello
[root@localhost ~] ll hello*
-rw-r--r-- 1 root root   0 Dec  7 10:37 hello20201205
-rw-r--r-- 1 root root   0 Dec  7 10:37 hello20201206
-rw-r--r-- 1 root root   0 Dec  7 10:37 hello20201207
```

Also, we can do calculation in script with variables.

```shell
#!/bin/bash
# Program:
#   Program will calculate the sum of two values from users.
# History:
#   2020/12/07 Minzhi First Release
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

read -p "Input the first number: " num1
read -p "Input the second number: " num2

declare -i sum=${num1}+${num2}
echo -e "The sum of two number is ${sum}."

exit 0
```

```bash
[root@localhost ~] ./sum.sh
Input the first number: 1
Input the second number: 2
The sum of two number is 3.
```

### Script Execution

There are two ways to execute a script -- `bash` or `source`.

The distinction is that `bash` will execute the script in a new process, while `source` will in current process, meaning system will be unable to capture the variable in the script when executing with `bash`.

```bash
# the difference between bash and source

___Father Process___        Bash         |----->
                   |                     |
                   |____Child Process____|


___Father Process_________Source_________----->

```

## Control Flow

### Test Command

- `test`
`test` is a super useful and significant command in shell programming, which is used to check file types and compare values.

| Test Flag for File | Description |
| :----: | :----: |
| `-e` | check if filename exists |
| `-f` | check if filename exists and if it is a file |
| `-d` | check if filename exists and if it is a directory |
| `-b` | check if filename exists and if it is a block device |
| `-c` | check if filename exists and if it is a character device |
| `-S` | check if filename exists and if it is a Socket file |
| `-p` | check if filename exists and a FIFO(pipe) file |
| `-L` | check if filename exists and a link file |

| Test Flag for Permission | Description |
| :----: | :----: |
| `-r` | check if filename exists and is readable |
| `-w` | check if filename exists and is writeable |
| `-x` | check if filename exists and is executable |
| `-u` | check if filename exists and has SUID attribute |
| `-g` | check if filename exists and has SGID attribute |
| `-k` | check if filename exists and has Sticky Bit attribute |
| `-s` | check if filename exists and is a non-blank file |

| Test Flag for File Comparison | Description |
| :----: | :----: |
| `-nt` | if file1 is newer than file2 |
| `-ot` | if file1 is older than file2 |
| `-ef` | if file1 is same as file2, judged by inode |

| Test Flag for Integer Comparison | Description |
| :----: | :----: |
| `-eq` | if x equals y |
| `-ne` | if x is not equal to y |
| `-gt` | if x is greater than y |
| `-lt` | if x is less than y |
| `-ge` | if x is greater than or equal to y |
| `-le` | if x is less than or equal to y |

| Test Flag for String Comparison | Description |
| :----: | :----: |
| `test -z  string` | true if string is zero |
| `test -n  string` | true if string is not zero |
| `test str1 == str2` | true if str1 is equal to str2 |
| `test str1 != str2` | true if str1 is not equal to str2 |

| Test Flag for Logic Expression | Description |
| :----: | :----: |
| `-a` | if condition1 and condition2 |
| `-o` | if condition1 or condition2 |
| `!` | if not condition | 

```shell
#!/bin/bash
# Program:
#   User input a filename, the program will check following:
#   1.) exist?  2.) file/directory  3.) file permissions
# History:
#   2020/12/07 Minzhi First Release
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

echo -e "Please input a filename, I will check the file type and permission.\n"
read -p "Input a filename: " filename

# test if getting input from user properly
test -z ${filename} && echo "You must input a legal filename." && exit 0

# check file type
test ! -e ${filename} && echo "The file does not exist!" && exit 0
test -f ${filename} && echo filetype="file" 
test -d ${filename} && echo filetype="directory"

# check permission
test -r ${filename} && perm="readable"
test -w ${filename} && perm="${perm} writeable"
test -x ${filename} && perm="${perm} executable"

echo -e "The filename: ${filename} is a ${filetype}."
echo -e "And the permissions are: ${perm}."

exit 0
```

```bash
[root@localhost ~] ./fileChecker.sh
Please input a filename, I will check the file type and permission.

Input a filename: sh02.sh
The filename: sh02.sh is a file.
And the permissions are: readable writeable executable.
```

`test` has a symbolic form, `[]`.

```bash
[root@localhost ~] [ -z "$HOME" ] ; echo $?
```

- there is a blank space on inner side of each square bracket.
- all variables within square brackets should be included by double quotes, and all constants by single quotes so that it will be interpreted properly.
- in equal judgement, we could use `=` or `==`, but the latter is suggested.

There is a negative example here,

```bash
[root@localhost ~] name="Russo Lee"
[root@localhost ~] [ $name == "dog" ]
bash: [: too many arguments

# 'cause it will be interpreted as [ Russo Lee == "dog" ]
```

```shell
#!/bin/bash
# Program:
#   This program will shows the user's choice.
# History:
#   2020/12/07 Minzhi First Release
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

read -p "Please input (Y/N)" yn
[ "${yn}" == "Y" -o "${yn}" == "y" ] && echo "OK, continue" && exit 0
[ "${yn}" == "N" -o "${yn}" == "n" ] && echo "No, interrupt" && exit 0


echo "Sorry, i don't know what you mean." && exit 0
```

### Default Variables

Bash script has some builtin variables.

- `$#`: the number of arguments.
- `$@`: means `$1`, `$2`, `$3` and so on, each of which is independent.
- `$*`: means `"$1 $2 $3 $4" ...`, each argument is separated by blank space by default.

```bash
/path/to/script  opt1 opt2 opt3 ...
    ^ $0          ^$1  ^$2  ^$3 ...
```

```shell
#!/bin/bash
# Program:
#   This script will show how to use default variables.
# History:
#   2020/12/07 Minzhi First Release
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

echo "The script name is $0"
echo "Total parameter number is $#"

[ "$#" -lt 2 ] && echo "The number of parameter is less than 2. Stop here." && exit 0

echo "Your whole parameter is: $*" # $@ or $*
echo "The 1st parameter is: $1"
echo "The 2nd parameter is: $2"

exit 0
```

```bash
[root@localhost ~] ./defaultPara.sh 1 2 3
The script name is ./sh07.sh
Total parameter number is 3
Your whole parameter is: 1 2 3
The 1st parameter is: 1
The 2nd parameter is: 2
```

- `shift`
`shift` is used to shift parameters in a command. Let's explain it with an example.

```shell
#!/bin/bash
# Program:
#   This script will show how shift works.
# History:
#   2020/12/07 Minzhi First Release
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

echo "Total parameter number is ===> $#"
echo "Your whole parameter is '$@'"

shift
echo "Total parameter number is ===> $#"
echo "Your whole parameter is '$@'"

shift 3
echo "Total parameter number is ===> $#"
echo "Your whole parameter is '$@'"

exit 0
```

```bash
[root@localhost ~] ./sh08.sh 1 2 3 4 5 6 7 8
Total parameter number is ===> 8
Your whole parameter is '1 2 3 4 5 6 7 8'
Total parameter number is ===> 7
Your whole parameter is '2 3 4 5 6 7 8'
Total parameter number is ===> 4
Your whole parameter is '5 6 7 8'
```

### If-Then Clause

```shell
if [ condition ]; then
    ...
fi

# there are two ways for more then one conditions

if [ condition1 -o condition2 -a ... ]; then
    ...
fi

# or 

if [ condition1 ] || [ condition2 ] && ...; then
    ...
fi

# multi-layer if-then clause

if [ condition ]; then
    ...
elif [ condition ]; then
    ...
else
    ...
fi
```

Let's change the example in `test` part.

```shell
#!/bin/bash
# Program:
#   This program will shows the user's choice.
# History:
#   2020/12/07 Minzhi First Release
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

read -p "Please input (Y/N)" yn
if [ "${yn}" == "Y"] || [ "${yn}" == "y" ]; then 
    echo "OK, continue"
elif [ "${yn}" == "N"] || [ "${yn}" == "n" ]; then
    echo "No, interrupt"
else
    echo "Sorry, i don't know what you mean."
fi

```

Now let's try to do something about host network management. `netstat -tuln` is used to check service ports of a linux host, where `Local Address` is an important record. `0.0.0.0` means open to all users on the internet whereas `127.0.0.1` only open for this host. 80 port is for www, 22 for ssh, 21 for ftp, 25 for mail, 111 for RPC(remote procedure call).

```bash
[root@localhost ~] netstat -tuln
Proto Recv-Q Send-Q Local Address     Foreign Address     State
tcp        0      0 0.0.0.0:80        0.0.0.0:*           LISTEN
tcp        0      0 0.0.0.0:21        0.0.0.0:*           LISTEN 
tcp        0      0 0.0.0.0:22        0.0.0.0:*           LISTEN
udp        0      0 127.0.0.1:323     0.0.0.0:* 
udp        0      0 0.0.0.0:68        0.0.0.0:* 
udp6       0      0 ::1:323           :::* 
```

Given knowledge above, we will write a script to check opened services on the host.

```shell
#!/bin/bash
# Program:
#   Using netstat and grep to detect WWW, SSH, FTP and Mail services.
# History:
#   2020/12/08 Minzhi First Release
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

echo "Now, I will detect services on your linux server."
echo -e "The www, ftp, ssh, and mail will be detected! \n"

checkItem=$(netstat -tuln | grep ":80")
if [ "${checkItem}" != "" ]; then
    echo "WWW is running on your host."
fi

checkItem=$(netstat -tuln | grep ":22")
if [ "${checkItem}" != "" ]; then
    echo "SSH is running on your host."
fi

checkItem=$(netstat -tuln | grep ":21")
if [ "${checkItem}" != "" ]; then
    echo "FTP is running on your host."
fi

checkItem=$(netstat -tuln | grep ":25")
if [ "${checkItem}" != "" ]; then
    echo "Mail service is running on your host."
fi

```

### Case-Esac Clause

```shell
case ${var} in
    "key1")
        ...
        ;;
    "key2")
        ...
        ;;
    *)
        ...
        exit 1
        ;;
esac
```

```shell
#!/bin/bash
# Program:
#   Show "Hello" from $1 by using case-esac clause.
# History:
#   2020/12/08 Minzhi First Release
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

case $1 in
    "hello")
        echo "Hello world!"
        ;;
    "")
        echo "You MUST input parameters, ex> {$0 word}"
        ;;
    *)
        echo "Usage $0 {hello}"
        ;;
esac
```

```bash
[root@localhost ~] ./sh09.sh
You MUST input parameters, ex> {./sh09.sh word}
[root@localhost ~] ./sh09.sh hello
Hello world!
```

A lot of scripts of system services are written in this way. Look at `/etc/init.d/syslog`. If we want to restart syslog service, just key in `/etc/init.d/syslog restart`, then the script will check `$1` and do some tasks in that condition.

## Function

Function in shell script is similar to C, which is designed for users to utilize a code segmentation conveniently.

```shell
function fname() {
    ...
}
```

```shell
#!/bin/bash
# Program:
#   Use function to print information.
# History:
#   2020/12/08 Minzhi First Release
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

function printNum() {
    echo "Your choice is $1"
}

echo "This program will print your selection."

case $1 in
    "one")
        printNum 1
    ;;
    "two")
        printNum 2
    ;;
    "three")
        printNum 3
    ;;
    *)
        echo "Usage $0 {one|two|three}"
    ;;
esac
```

The example above shows how to transfer arguments to function. It is pretty straightforward, since you can just see a function as a sub-script.

## Loop

### While Loop

#### While-Do-Done

Similar to C syntax, `while-do-done` in shell script is a conditional loop. When condition is true, the codes within `do-done` will be executed.

```shell
while [ condition ]
do
    ...
done
```

#### Until-Do-Done

Different from `while-do-done`, `until-do-done` will execute the codes in the body when the condition is false.

```shell
until [ condition ]
do
    ...
done
```

Let's do a calculation from 1 to N by function.

```shell
#!/bin/bash
# Program:
#   Use function to calculate the sum from 1 to N.
# History:
#   2020/12/08 Minzhi First Release
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

function calc() {
    declare -i n=$1
    declare -i i=1

    while [ ${i} -le ${n} ]  # <<== integer comparison
    do
        sum=${sum}+${i}
        i=${i}+1
    done

    # until [ ${i} -gt ${n} ]
    # do
    #     sum=${sum}+${i}
    #     i=${i}+1
    # done
}

if [ "$#" -lt "1" ]; then    # <<== string comparison
    echo "Please input a number, ex> $0 {100}"
    exit 127
fi

# var sum is responsible for taking the result back from function
declare -i sum
calc $1
echo "The sum from 1 to $1 is ${sum}."
```

```bash
[root@localhost ~] ./sh10.sh
Please input a number, ex> ./sh10.sh {100}
[root@localhost ~] echo $? 
127
[root@localhost ~] ./sh10.sh 100
The sum from 1 to 100 is 5050.
```

### For Loop

#### For-Do-Done

`for-do-done` loop has its C version of `for-in`, whose syntax looks like this.

```shell
for var in con1 con2 con3 ...
do
    ...
done
```

There are tree useful script examples, the first is to record detailed information of host accounts in a file called `users.info`.

```shell
#!/bin/bash
# Program:
#   Use id, finger command to check system account's information 
#   and backup into users.info file.
# History:
#   2020/12/08 Minzhi First Release
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

touch users.info

users=$(cut -d ':' -f1 /etc/passwd)
for username in ${users}
do
    id ${username} >> users.info
    finger ${username} >> users.info
    echo "" >> users.info
done
```

```bash
[root@localhost ~] ./sh11.sh
[root@localhost ~] cat users.info
uid=0(root) gid=0(root) groups=0(root)
Login: root               Name: root
Directory: /root          Shell: /bin/zsh
On since Tue Dec  8 10:08 (CST) on pts/0 from 1.80.149.39
   5 seconds idle
No mail.
No Plan.

uid=1(bin) gid=1(bin) groups=1(bin)
Login: bin                Name: bin
Directory: /bin           Shell: /sbin/nologin
Never logged 
...
```

Another example is to check whether hosts in a cluster are online or not.

```shell
#!/bin/bash
# Program:
#   Check if hosts are online by ping command.
# History:
#   2020/12/08 Minzhi First Release
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

network_pref="192.168.1"
for host in $(seq 1 100)  # <<== use 'seq' to get a sequence of numbers
do
    ping -c 1 -w 1 ${network_pref}.${host} &> /dev/null && returnFlag=0 || returnFlag=1
    if [ "${returnFlag}" == 0 ]; then
        echo "Server ${network_pref}.${host} is online."
    else
        echo "Server ${network_pref}.${host} is offline."
    fi
done
```

```bash
[root@localhost ~] ./sh12.sh
Server 192.168.1.1 is offline.                   
Server 192.168.1.2 is offline.
Server 192.168.1.3 is offline.
Server 192.168.1.4 is offline.
Server 192.168.1.5 is offline.
Server 192.168.1.6 is offline.
...
```

The final one is to check the permission of files in a directory.

```shell
#!/bin/bash
# Program:
#   Check out the permission of files in a directory.
# History:
#   2020/12/08 Minzhi First Release
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

read -p "Please input a directory name: " dir

if [ "${dir}" == "" ] || [ ! -d "${dir}" ]; then
    echo "Error: the ${dir} is NOT a legal directory in your system. Please check if it exists!"
    exit 1
fi

filelist=$(ls $dir)
for file in ${filelist}
do
    perm=""
    test -r "${dir}/${file}" && perm="${perm}readable"
    test -w "${dir}/${file}" && perm="${perm} writable"
    test -x "${dir}/${file}" && perm="${perm} executable"

    echo "The file ${dir}/${file} permission is: ${perm}"
done
```

```bash
[root@localhost ~] ./sh13.sh
Please input a directory name: /root/shell
The file /root/shell/sh02.sh permission is: readable writable executable
The file /root/shell/sh03.sh permission is: readable writable executable
The file /root/shell/sh07.sh permission is: readable writable executable
The file /root/shell/sh08.sh permission is: readable writable executable
```

#### C-like For-Loop

```shell
for ( ( initialVal; condition; step ) )
do

done
```

```shell
#!/bin/bash
# Program:
#   The program will count the sum from 1 to # from users.
# History:
#   2020/12/08 Minzhi First Release
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

read -p "Please input a number, I will count for 1+2+3+...+N: " num

declare -i sum=0
for (( i=1; i<=${num}; i=i+1 )) # <<== (( ... )) is a symbol for numerical operation
do
    sum=${sum}+${i}
done

echo "The sum of 1 from ${num} equals ${sum}."
```

## Debug

`sh` provide some tools for syntax check for shell script.

```bash
sh -[nvx] script.sh
# where,
# -n: do NOT execute script, and only check syntax.
# -v: before executing script, output the script code first.
# -x: display the process of execution.

[root@localhost ~] sh -x sh14.sh
+ PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/root/bin
+ export PATH
+ read -p 'Please input a number, I will count for 1+2+3+...+N: ' num
Please input a number, I will count for 1+2+3+...+N: 10
+ declare -i sum=0
+ (( i=1 ))
+ (( i<=10 ))
+ sum=0+1
+ (( i=i+1  ))
+ (( i<=10 ))
+ sum=1+2
+ (( i=i+1  ))
+ (( i<=10 ))
+ sum=3+3
+ (( i=i+1  ))
+ (( i<=10 ))
+ sum=6+4
+ (( i=i+1  ))
+ (( i<=10 ))
+ sum=10+5
+ (( i=i+1  ))
+ (( i<=10 ))
+ sum=15+6
+ (( i=i+1  ))
+ (( i<=10 ))
+ sum=21+7
+ (( i=i+1  ))
+ (( i<=10 ))
+ sum=28+8
+ (( i=i+1  ))
+ (( i<=10 ))
+ sum=36+9
+ (( i=i+1  ))
+ (( i<=10 ))
+ sum=45+10
+ (( i=i+1  ))
+ (( i<=10 ))
+ echo 'The sum of 1 from 10 equals 55.'
The sum of 1 from 10 equals 55.
```

<EndMarkdown>