# Account Management

## Table of Contents
- [Account and Group](#accountandgroup)
	- [UID and GID](#uidandgid)
	- [User Account](#useraccount)
		- [passwd](#passwd)
		- [shadow](#shadow)
	- [Group](#group)
		- [Effective Group](#effectivegroup)
		- [gshadow](#gshadow)
- [User Management](#usermanagement)
	- [Create an Account](#createanaccount)
	- [Setting Password](#settingpassword)
	- [Modification](#modification)
	- [Delete an Account](#deleteanaccount)
	- [User Tools](#usertools)
- [Group Management](#groupmanagement)
	- [Create a Group](#createagroup)
	- [Modify Group](#modifygroup)
	- [Delete a group](#deleteagroup)
	- [Manager](#manager)
- [Access Control List](#accesscontrollist)
- [Identity](#identity)
	- [su](#su)
	- [sudo](#sudo)
	- [visudo](#visudo)
		- [a single user](#asingleuser)
		- [a group](#agroup)
		- [alias](#alias)
- [PAM](#pam)
	- [Nologin](#nologin)
	- [PAM Modules](#pammodules)
- [Others](#others)
	- [Log File](#logfile)
	- [Message](#message)
	- [Mail](#mail)

<TableEndMark>

## Account and Group

### UID and GID

When comes to account management of Linux, the first question is how the system distinguish users or accounts? The answer is by UID(User Identity Document) or GID(Group Identity Document).

```bash
[root@localhost ~] grep 'root' /etc/passwd
root:*:0:0:System Administrator:/var/root:/bin/sh
# notice that
# the UID and GID of root is 0
```

### User Account

When a user logins into a system, the system will do following things:

- check if the user name is found in `/etc/passwd`. If so, record its UID, GID, password, home directory, and shell settings.
- check if recorded password matches that in `/etc/shadow`. If so, then the user will login into the system.

#### passwd

In `/etc/passwd`, each line records information of an account.

```bash
[root@localhost ~] head -n 4 /etc/passwd
root:x:0:0:root:/root:/bin/zsh
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin
adm:x:3:4:adm:/var/adm:/sbin/nologin
```

Now let's specify what the meaning is of each part.

- User Name: the name of account, which is responding to UID, the third part of an account.

- Password: which often appears as 'x', since the password is saved into `/etc/shadow` for security reasons.

- UID: user identity document.

| Range of UID | Description |
| :---: | :---: |
| 0 (admin) | When UID is 0, the account is for root, who has the most significant permission in the system. |
| 1 ~ 499 (system) | The system User IDs from 0 to 99 should be statically allocated by the system, and shall not be created by applications. The system User IDs from 100 to 499 should be reserved for dynamic allocation by system administrators. |
| 500 ~ 65535 | The UID in this range is reserved for common account. |

```bash
[root@localhost ~] cat /etc/passwd | grep 'MinzhiQu'
MinzhiQu:x:1000:1000::/home/MinzhiQu:/bin/zsh
```

Notice that in my machine, the common account is allocated UID starting from 1000. Therefore, different machines may have various starting number for the UID of common users.

- GID: Group Identity Document, whose detailed information is recorded in `/etc/group`.

- Description: the description of an account.

- Home Directory: the home directory of an account.

- Shell: specify the default shell which is used when user logins in.

#### shadow

In `/etc/shadow`, the passwords of users is saved here.

```bash
[root@localhost ~] head -n 4 /etc/shadow
root:$6$QWzNeeKXx7EpBzeU$8UV8.hqqapj5b3w1Wlzt4Hzt4FSEd5xE0hTfXdree2dN/7PJ5xUnKvkHQUUt3toR7EYS1p7RpiTcmlCsBzTRr.::0:99999:7:::
bin:*:18353:0:99999:7:::
daemon:*:18353:0:99999:7:::
adm:*:18353:0:99999:7:::
```

- User Name: the name of user.

- Password: records encrypted password.

- Modified Time: the date when the password is changed last time. (for password)

- Unchangeable Time: the length of time when the password is not allowed to change. (for password)

- Change Time: the length of time when the password needs to be changed. 99999 days (or 273 years) means no requirement of changing password. (for password)

- Notification Time: the system will notify users that the password is going to be expired *n* days before password expiration. 7 means 7 days before expiration day. (for password)

- Extended Time: means the account is still available *n* days after expiration day. (for password)

- Expiration day: when an account is disabled. The start time is 1970 by default. (for account)

### Group

Now let's talk about GID.

```bash
[root@localhost ~] head -n 4 /etc/group
root:x:0:
bin:x:1:          
daemon:x:2:          
sys:x:3: 
```

There are 4 segments in each line.

- Group Name: the name of a group.

- Group Password: the password of a group, which often appears as 'x'. The encrypted password is recorded in '/etc/gshadow'.

- GID: group identity document.

- Members: all members of the group, noting that the member whose initial group is the group is not recorded in the segment. For example, for group 'yolkoo', it has 3 members - yolkoo, brain, laser. The record would be as follows,

```bash
yolkoo:x:1001:brain,laser
```

#### Effective Group

As we discussed above, each account has a group with the same name, which is termed *Initial Group*. Different from initial group, effective group specifies which group identity the user acts currently.

Take an example,

```bash
# add yolkoo to group root with root identity
[root@localhost ~] usermod -G root yolkoo

# log in system as yolkoo
# use 'groups' command to show groups the user belongs to
# the first group is effective group
[yolkoo@localhost ~] groups
yolkoo root
[yolkoo@localhost ~] touch test && ll
-rw-r--r--. 1 yolkoo yolkoo 0 Feb 24 22:42 test  

# change effective group to root with 'newgrp' command
[yolkoo@localhost ~] newgrp root
[yolkoo@localhost ~] groups
root yolkoo
[yolkoo@localhost ~] touch test && ll
-rw-r--r--. 1 yolkoo root 0 Feb 24 22:42 test 
```

- `newgrp`
newgrp allows users to log in to a new group, which will create a new shell which copy all environment from father process except group information.

```bash
   yolkoo            yolkoo
  --------|        |-------->   father process
   newgrp |  root  | exit
          |--------|            child process
```

#### gshadow

`/etc/gshadow` is somewhat similar to `/etc/group`,

```bash
[root@localhost ~] head -n 4 /etc/gshadow
root:::  
bin:::          
daemon:::              
sys:::  
```

The only difference from `group` are the second and third segments, if '!' appears on the second segment, it means that there is no group password and no group administrator.

On the third segment, it records the name of group administrator.

## User Management

#### Create an Account

- `useradd`
`useradd` is used to create a new user or update default new user information.

```bash
useradd [-ugcdrsef] (username)
# where,
# -u: specify the numerical value of the user's ID.
# -g: the group name or number of the user's initial login group. The group name must exist. A group number must refer to an already existing group.
# -c: add description.
# -d: specify home directory.
# -r: create a system account.
# -s: specify the login shell.
# -e: specify the expiration time of account, 'YYYY-MM-DD'. The 8th segment in /etc/shadow.
# -f: specify extended time when the password is expired, 0 for disable immediately, -1 for never disable. The 7th segment in /etc/shadow.
```

There is a reference file for default setting of `useradd`, which is in `/etc/default/useradd`. We can visit the content of that file by `vi` or following command,

```bash
[yolkoo@localhost ~] useradd -D
GROUP=100         # => initial group                   
HOME=/home        # => home directory     
INACTIVE=-1       # => password disabled time, -1 never      
EXPIRE=           # => account expiration time      
SHELL=/bin/bash   # => default shell       
SKEL=/etc/skel    # => benchmark for home directory     
CREATE_MAIL_SPOOL=yes  # => if create a mail for users
```

Some configuration need to be explained more specifically,

- GROUP: there are two different kind of mechanism, private and public. In private one, the system will create a new group whose name is same as username, thereby GROUP is useless. This mechanism is often used in RHEL, Fedora, and CentOS. In public one, the system will add new user to the group whose UID is 100. The mechanism is used in SuSE for example.

- SKEL: when creating a home directory, the system will copy the content of '/etc/skel' to new home directory. Hence, if we want to give a bunch of users same environment settings, we are able to create a `.bashrc` in `/etc/skel`, and edit it. If we want there is a `www` directory in home directory of new users, just make a `www` directory in `/etc/skel`.

For more default settings, we are able to find them in `/etc/login.defs`.

```bash
[yolkoo@localhost ~] cat /etc/login.defs
...
MAIL_DIR        /var/spool/mail
...
PASS_MAX_DAYS   99999   # Maximum number of days a password may be used.
PASS_MIN_DAYS   0       # Minimum number of days allowed between password changes.
PASS_MIN_LEN    5       # Minimum acceptable password length.
PASS_WARN_AGE   7       # Number of days warning given before a password expires.
...
UID_MIN                  1000
UID_MAX                 60000
# System accounts
SYS_UID_MIN               201
SYS_UID_MAX               999
...

CREATE_HOME     yes
# The permission mask is initialized to this value. If not specified, 
# the permission mask will be initialized to 022.
UMASK           077
```

#### Setting Password

- `passwd`
`passwd` is used to update user's authentication tokens.

```bash
passwd [--stdin, -luS] (username)
# where,
# -stdin: passwd should read password from standard input, which can be a pipe.
# -l: will lock the password of a specific account.
# -u: will unlock the password of a specific account.
# -S, --status: will output a short information about the status of the password for a given account.
```

```bash
[root@localhost ~] passwd -S MinzhiQu
MinzhiQu PS 2021-02-08 0 99999 7 -1 (Password set, SHA512 crypt.) 
[root@localhost ~] passwd -l MinzhiQu
Locking password for user MinzhiQu.    
passwd: Success
[root@localhost ~] passwd -u MinzhiQu
Unlocking password for user MinzhiQu. 
passwd: Success 
```

Notice that: if no username follows `passwd`, then the instruction will change the password of root. Resetting the password of root doesn't need old password of root.

- `chage`
`chage` is used to change user password expiry information, and to get detailed information of the password for a specific account.

```bash
chage [-ld] (username)
# where,
# -l: will list detailed information about the password.
# -d: sets the number of days since January 1st, 1970 when the password was last changed.
```

```bash
[root@localhost ~] chage -l MinzhiQu
Last password change                              : Feb 09, 2021 
Password expires                                  : never 
Password inactive                                 : never
Account expires                                   : never 
Minimum number of days between password change    : 0     
Maximum number of days between password change    : 99999
Number of days of warning before password expires : 7   

# create an account whose password is same as its name, and the password
# has to be reset after login.
[root@localhost ~] useradd test
[root@localhost ~] passwd test
Changing password for user test.      
New password:          
Retype new password:                                
passwd: all authentication tokens updated successfully.
# set the time when changing password last time as Jan 1st, 1970.  
[root@localhost ~] chage -d 0 test

# now when I log in as test
You are required to change your password immediately (root enforced)
Last login: Sat Feb 27 20:35:58 2021
WARNING: Your password has expired.
You must change your password now and login again!
Changing password for user test.
Changing password for test.
(current) UNIX password: 
# after resetting password, the user is able to login.
```

#### Modification

- `usermod`
`usermod` is used to modify a user account.

```bash
usermod [-cdegGlsuLU] (username)
# where,
# -c: change the description of an account.
# -d: change the home directory of a given account.
# -e: + "YYYY-MM-DD" change the expiry time  of an account.
# -g: set the primary group.
# -G: set the secondary group.
# -l: change the name of an account.
# -s: chage the shell of an account.
# -u: chage the uid of an account.
# -L/U: lock/unlock an account.
```

```bash
[root@localhost ~] cat /etc/shadow | grep test 
test:$6$1iJqcrPP$IBU8WFSjRvqtC2Grlw1QZ.zd1xSMlpW/46kpzunWPwxisCxZcTqtSl5GtQCPoAOpRTLjq/Anu00zartwYUWzc/:18686:0:99999:7:::
[root@localhost ~] usermod -e "2020-12-24" test
[root@localhost ~] cat /etc/shadow | grep test  
test:$6$1iJqcrPP$IBU8WFSjRvqtC2Grlw1QZ.zd1xSMlpW/46kpzunWPwxisCxZcTqtSl5GtQCPoAOpRTLjq/Anu00zartwYUWzc/:18686:0:99999:7::18620:
```

- `chown`
`chown` is used to change file owner and group.

```bash
chown [-R] (filename)
# where,
# -R: recursive modification.
```

```bash
[root@localhost ~] chown -R test:test /home/test
```

#### Delete an Account

- `userdel`
`userdel` is used to delete an account.

```bash
userdel [-r] (username)
# where,
# -r: also delete home directory.
```

```bash
[root@localhost ~] userdel -r test
```

#### User Tools

- `finger`
`finger` is used to display information about the system users.

```bash
finger [-s] (username)
# where,
# -s: displays the user's login name, real name, terminal name and write status.
```

```bash
[root@localhost ~] finger MinzhiQu
Login: MinzhiQu                         Name:  
Directory: /home/MinzhiQu               Shell: /bin/zsh  
On since Sat Feb 27 21:26 (EST) on pts/0 from gateway 
   7 seconds idle                  
No mail.                                                    
No Plan.
# Name: the content of description.
# Mail: get information from /var/spool/mail.
# Plan: get information from ~/.plan.

# Also we can edit our plans
[root@localhost ~] echo "This is my plan." >  ~/.plan
[root@localhost ~] finger MinzhiQu
Login: MinzhiQu                         Name:  
Directory: /home/MinzhiQu               Shell: /bin/zsh  
On since Sat Feb 27 21:26 (EST) on pts/0 from gateway 
   7 seconds idle                  
No mail.                                                    
Plan:
This is my plan.
```

- `chfn`
`chfn` is used to change your finger information.

```bash
chfn (username)
```

```bash
[root@localhost ~] chfn MinzhiQu
Changing finger information for MinzhiQu. 
Name []: Minzhi Qu                                
Office []: Unicorn Inc. Xian                          
Office Phone []: 13309285508                           
Home Phone []: 13309285508
                                                                     
Finger information changed.

# In fact, it adds some information to the 5th segment in passwd file.
[root@localhost ~] grep MinzhiQu /etc/passwd
MinzhiQu:x:1000:1000:Minzhi Qu,Unicorn Inc. Xian,13309285508,13309285508:/home/MinzhiQu:/bin/zsh  
```

- `chsh`
`chsh` is used to change user's login shell.

```bash
chsh [-ls] 
# where,
# -l: list all available shells.
# -s: set user's shell.
```

```bash
[root@localhost ~] chsh -s /bin/csh && grep root /etc/passwd
root:x:0:0:root:/root:/bin/csh
```

- `id`
`id` is used to list user's information about UID, GID.

```bash
id (username)
```

```bash
[root@localhost ~] id
uid=0(root) gid=0(root) groups=0(root) context=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 
```

## Group Management

#### Create a Group

- `groupadd`
`groupadd` is used to add a new group.

```bash
groupadd [-g gid, -r] (group_name)
# where,
# -g: specify a gid
# -r: create a system group
```

#### Modify Group

- `groupmod`
`groupmod` is used to modify attributes of a group.

```bash
groupmod [-g gid, -n name] (group_name)
# where,
# -g: change gid
# -n: change name
```

#### Delete a group

- `groupdel`
`groupdel` is used to delete a given group.

```bash
groupdel (group_name)
```

```bash
[root@localhost ~] groupdel MinzhiQu
groupdel: cannot remove users primary group
# there are two ways to solve the problem:
# 1. delete user whose primary group is the group.
# 2. change users primary group (aka. change gid)
```

#### Manager

- `gpasswd`
`gpasswd` is used to manage a group.

```bash
# sets group password
gpasswd (group_name)

gpasswd [-A user1, ...; -M user2, ...] (group_name)
# where,
# -A: assign administration power to users
# -M: add a group of users to the group

gpasswd [-rR] (group_name)
# where,
# -r: remove the password of a group
# -R: make the password of a group disabled

gpasswd [-ad] (group_name)
# where,
# -a: add users to the group
# -d: delete users from the group
```

```bash
# create a system group testgroup
[root@localhost ~] groupadd -r testgroup

# set group password
[root@localhost ~] gpasswd testgroup
Changing the password for group testgroup
New password:
Re-enter new password:

# set user MinzhiQu as group manager
[root@localhost ~] gpasswd -A MinzhiQu testgroup
[root@localhost ~] grep testgroup /etc/group /etc/gshadow
/etc/group:testgroup:x:1002: 
/etc/gshadow:testgroup:$6$.xLNe/ZE5Ka/qnF$LnqOx27DuhBsnx3nUVWZkaEPub9QdUOXFr2aIsNMsGSEdDsnk9rJ4DWRIUztz4yVIpi7bhYu3B92B0elA6Ypc/:MinzhiQu:
```

## Access Control List

In computer security, an access-control list (ACL) is a list of permissions associated with a system resource (object). An ACL specifies which users or system processes are granted access to objects, as well as what operations are allowed on given objects.

Each entry in a typical ACL specifies a subject and an operation. For instance, if a file object has an ACL that contains (Alice: read,write; Bob: read), this would give Alice permission to read and write the file and Bob to only read it.

- `setfacl`
`setfacl` is used to set file access control lists.

```bash
setfacl [-bRd; {-m | -x} acl args] (filename)
# where,
# -m: set acl args to a file.
# -x: delete acl args to a file.
# -b: clear all acl settings.
# -R: set acl args recursively for existed files.
# -d: only works for directory, similar to -R, but the acl will be inherited.
```

- `getfacl`
`getfacl` is used to display file access control lists.

```bash
getfacl (filename)
```

```bash
# case 1: give a user acl permission
[root@localhost ~] touch acl_test
[root@localhost ~] ll acl_test
-rw-r--r--. 1 root root    0 Mar  3 19:52 acl_test
[root@localhost ~] setfacl -m u:MinzhiQu:rx acl_test
[root@localhost ~] ll acl_test
-rw-r-xr--+ 1 root root 0 Mar  3 19:52 acl_test 

[root@localhost ~] getfacl acl_test
# file: acl_test
# owner: root
# group: root
user::r-x
user:MinzhiQu:r-x
group::r--
mask::r-x
other::r--

# if the segment of user is blank, it will be the owner of the file by default
[root@localhost ~] setfacl -m u::rwx acl_test
[root@localhost ~] ll acl_test
-rwxr-xr--+ 1 root root 0 Mar  3 19:52 acl_test
[root@localhost ~] getfacl acl_test
# file: acl_test
# owner: root
# group: root
user::rwx
user:MinzhiQu:r-x
group::r--
mask::r-x
other::r--

# case 2: give a group acl permission
[root@localhost ~] setfacl -m g:project:rx acl_test
[root@localhost ~] getfacl acl_test
# file: acl_test
# owner: root
# group: root
user::rwx
user:MinzhiQu:r-x
group::r--
group:project:r-x
mask::r-x
other::r--

# case 3: mask
[root@localhost ~] setfacl -m m:r acl_test
[root@localhost ~] getfacl acl_test
# file: acl_test
# owner: root
# group: root
user::rwx
user:MinzhiQu:r-x               #effective:r--
group::r--
group:project:r-x               #effective:r--
mask::r--
other::r--
```

IMPORTANT: for files with acl settings, the true permission should be found in acl, not by `ll` command.

```bash
# case 4: inherit
# if we want the new files in a directory will inherit acl from the directory,
[root@localhost ~] setfacl -m d:u:MinzhiQu:rx /srv/tencent
```

## Identity

### su

- `su`
`su` is used when running a command with substitute user and group ID.

```bash
su [-lm; -c cmd] (username)
# where,
# -l, -: starts shell as login shell with an environment similar to a real login
# -m: preserves the whole environment, ie does not set HOME, SHELL, USER nor LOG-NAME
# -c: pass command  to the shell 
```

```bash
# case 1: change to root as no-login shell
[MinzhiQu@localhost ~] su
Password:
[root@localhost ~] id
uid=0(root) gid=0(root) groups=0(root) context=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
# the environment is still MinzhiQu's
[root@localhost ~] env | grep 'Minzhi'
USER=MinzhiQu    
LOGNAME=MinzhiQu        
PATH=/usr/local/bin:/usr/bin:/home/MinzhiQu/bin:/usr/local/sbin:/usr/sbin                      
MAIL=/var/spool/mail/MinzhiQu                
PWD=/home/MinzhiQu             
OLDPWD=/home/MinzhiQu 
[root@localhost ~] exit

# case 2: change to root as login shell
[MinzhiQu@localhost ~] su -
Password:
[root@localhost ~] env | grep 'root'
HOME=/root        
USER=root            
LOGNAME=root          
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin 
PWD=/root    
OLDPWD=/root 
MAIL=/var/spool/mail/root       
ZSH=/root/.oh-my-zsh 
[root@localhost ~] exit

# case 3: just execute a command with root identity
[MinzhiQu@localhost ~] head -n 3 /etc/shadow
head: cannot open '/etc/shadow' for reading: Permission denied
[MinzhiQu@localhost ~] su - -c "head -n 3 /etc/shadow"
root:$6$QWzNeeKXx7EpBzeU$8UV8.hqqapj5b3w1Wlzt4Hzt4FSEd5xE0hTfXdree2dN/7PJ5xUnKvkHQUUt3toR7EYS1p7RpiTcmlCsBzTRr.::0:99999:7:::      
bin:*:18353:0:99999:7:::   
daemon:*:18353:0:99999:7::: 
```

### sudo

What is `sudo`? Let's start with how to use it.

```bash
sudo [-b, -u username]
# where,
# -b: execute in system, which will not affect current shell env.
# -u: change identity to a user, blank means root.
```

```bash
# case 1: create a file as the user sshd
[root@localhost ~] sudo -u sshd touch /tmp/mysshd
[root@localhost ~] ll /tmp/mysshd
-rw-r--r--. 1 sshd sshd   0 Mar  3 20:47 mysshd

# case 2: make a folder and create a file in it as the user MinzhiQu
[root@localhost ~] sudo -u MinzhiQu sh -c "mkdir ~MinzhiQu/www; cd ~MinzhiQu/www; echo 'This is index.html file.' > index.html"
[root@localhost ~] ll -a ~MinzhiQu/www
drwxr-xr-x. 2 MinzhiQu MinzhiQu   24 Mar  3 20:52 .                
drwx------. 6 MinzhiQu MinzhiQu 4.0K Mar  3 20:54 ..    
-rw-r--r--. 1 MinzhiQu MinzhiQu   25 Mar  3 20:52 index.html 
```

TIPS: `sh -c` allows us to execute a sequence of instructions.

But how does `sudo` work?

- when `sudo` is executed, the system will find in `/etc/sudoers` if the user has sudo power.
- If so, type in password to confirm.
- If the password is correct, the command is going to be executed.

BTW, if the user is same as the one who is going to be sudo-ed to, the password is unnecessary.

### visudo

As we talked about above, `/etc/sudoers` is a very important file for `sudo`.

There are several ways to set sudoers.

#### a single user

```bash
# case 1: give MinzhiQu root's power
[root@localhost ~] visudo
...
## Allow root to run any commands anywhere 
root    ALL=(ALL)       ALL  
MinzhiQu    ALL=(ALL)   ALL
...
```

- 1st col: user's account.
- 2nd col: allowed host origins.
- 3rd col: the users that can be changed to.
- 4th col: the commands that are allowed to be executed.

```bash
[MinzhiQu@localhost ~] head -n 3 /etc/shadow
head: cannot open ‘/etc/shadow’ for reading: Permission denied
[MinzhiQu@localhost ~] sudo head -n 3 /etc/shadow
[sudo] password for MinzhiQu:                     
root:$6$QWzNeeKXx7EpBzeU$8UV8.hqqapj5b3w1Wlzt4Hzt4FSEd5xE0hTfXdree2dN/7PJ5xUnKvkHQUUt3toR7EYS1p7RpiTcmlCsBzTRr.::0:99999:7:::
bin:*:18353:0:99999:7:::  
daemon:*:18353:0:99999:7::: 
```

#### a group

```bash
# case 2: give project group root's power
[root@localhost ~] visudo
...
## Allow group project to run any commands anywhere 
%project    ALL=(ALL)       ALL  
...

# add MinzhiQu to project group
[root@localhost ~] usermod -a -G project MinzhiQu
```

```bash
# case 3: no password needed
[root@localhost ~] visudo
...
## Allow group project to run any commands anywhere 
%project    ALL=(ALL)      NOPASSWD: ALL  
...

# case 4: add a password manager
[root@localhost ~] visudo
...
## Allow password manager to manage password
# following settings will give manager power to change root's password!
manager    ALL=(root)      /usr/bin/passwd  # DANGEROUS! 
...

# a more secure way
[root@localhost ~] visudo
...
## Allow password manager to manage password
manager    ALL=(root)     !/usr/bin/passwd, !/usr/bin/passwd root, /usr/bin/passwd [A-Za-z]*
...
```

#### alias

Also we are able to use alias to make code clear.

```bash
[root@localhost ~] visudo
...
User_Alias ADMPW = david, MinzhiQu, alex
Cmnd_Alias ADMPWCMD = !/usr/bin/passwd, !/usr/bin/passwd root, /usr/bin/passwd [A-Za-z]*
AMDPW     ALL=(root)     AMDPWCMD
...

# sets administrator accounts, so that every administrator is able to su
# root with their own passwords.
[root@localhost ~] visudo
...
User_Alias ADMIN = MinzhiQu
ADMIN    ALL=(root)     /bin/su -
```

## PAM

### Nologin

In general, nologin shell is not allowed to login linux. Many system accounts acts as nologin shell.

We are able to edit `/etc/nologin.txt` to tell nologin users why they are not allowed to login.

```
[root@localhost ~] echo "We are maintaining our server, please login later." > /etc/nologin.txt
[root@localhost ~] su - sshd
We are maintaining our server, please login later.
```

### PAM Modules

Pluggable Authentication Modules(PAM) is a bundle of modules for Linux to verify the authentication of a user, password, and so on.

To give us a intuition what pam looks like, let's see `/etc/pam.d/passwd`

```bash
[root@localhost ~] cat /etc/pam.d/passwd
#%PAM-1.0 
auth       include      system-auth
account    include      system-auth 
password   substack     system-auth   
-password   optional    pam_gnome_keyring.so use_authtok     
password   substack     postlogin 
```

- 1st col: verification type, including `auth`, `account`, `session`, and `password` in general.
- 2nd col: control flag, including `required`, `requisite`, `sufficient`, and `optional`
      - required: return success/failure, and pass data blob to the next pam module.
      - requisite: if return success, pass data blob to the next pam module, or stop verification and return failure.
      - sufficient: if return failure, pass data blob to the next pam module, or stop verification and return success.
      - optional: is not a true module to verify something, which is often used to echo tip info.
- 3rd col: name of pam modules.

## Others

### Log File

There are several commands used for accessing log of login info, such as `w`, `who`, `last`, `lastlog`.

```bash
[root@localhost ~] w
 04:16:42 up 11:25,  1 user,  load average: 0.01, 0.03, 0.05
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
root     pts/0    gateway          04:12    2.00s  0.08s  0.02s w
[root@localhost ~] lastlog
root             pts/0    gateway          Thu Mar  4 04:12:54 -0500 2021  
bin                                        **Never logged in** 
daemon                                     **Never logged in** 
adm                                        **Never logged in**
...  
sshd                                       **Never logged in**
postfix                                    **Never logged in**
chrony                                     **Never logged in**
MinzhiQu         pts/1    gateway          Wed Mar  3 21:15:39 -0500 2021
test             pts/2    gateway          Sat Feb 27 20:41:29 -0500 2021
alex                                       **Never logged in**
david            pts/1                     Tue Mar  2 22:33:49 -0500 2021
```

### Message

- `write`
`write` is used to say something to other users.

```bash
write (username) (terminal)
```

```bash
[root@localhost ~] write MinzhiQu pts/1
Hello world.
EOF
```

- `mesg`
`mesg` controls write access to your terminal.

```bash
# open message
[root@localhost ~] mesg y
# close message
[root@localhost ~] mesg n
```

### Mail

- `mail`
`mail` is used to send and receive Internet mail

```bash
[root@localhost ~] mail MinzhiQu -s "Greeting"
Nice to meet you.
.
Cc:   # meaning whether forward to other mails
[root@localhost ~]
```

<EndMarkdown>