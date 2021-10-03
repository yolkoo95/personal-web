# Disk and File System

## Table of Contents
- [Overview](#overview)
- [Ext2 File System](#ext2filesystem)
	- [File System](#filesystem)
		- [FAT and Ext2](#fatandext2)
		- [The Difference Between Two FSs](#thedifferencebetweentwofss)
	- [Ext2 and Directory](#ext2anddirectory)
	- [Ext2 and Files](#ext2andfiles)
	- [Location of a File](#locationofafile)
	- [Ext2/Ext3 Journaling File System](#ext2/ext3journalingfilesystem)
	- [Mount Point](#mountpoint)
- [Related Command](#relatedcommand)
	- [Hard Link](#hardlink)
	- [Symbolick Link](#symbolicklink)
	- [Partition and Format](#partitionandformat)
	- [Mount Command](#mountcommand)

<TableEndMark>

## Overview

- Devices and their filename in Linux

| Device | Filename in Lniux |
| :---: | :---: |
| IDE Hard Disk | `/dev/hd[a-d]` |
| SCSI/SATA/USB Hard Disk | `/dev/sd[a-p]` |
| U-disk | `/dev/sd[a-p]` |
| Soft Drive | `/dev/fd[0-1]` |
| Printer | `/dev/usb/lp[0-15]` |
| Mouse | USB: `/dev/usb/mouse[0-15]`, PS2: `/dev/psaux` |
| CD ROM | `/dev/cdrom` |
| Current Mouse | `/dev/mouse` |

- The composition of hard disk
    - `Tracks`: a platter is divided into many rings, which is called track.
    - `Heads`: is used to fetch data from platters.
    - `Cylinder`: All of the same tracks on each platter are collectively known as a cylinder. the # of tracks equals that of cylinders. **The minimum unit of partition is cylinder.**
    - `Sector`: is the minimum unit of hard disk, usually 512 bytes.
    - Size of a hard disk = `heads * tracks * sectors`. Any sector could be located as `(head, sector, track)`, which can be thought as `(z, x, y)` if you wish.

![Hard Disk](codehome/src/img/linux/harddisk.png)

- The first sector is super important for it has `Master Boot Record(MBR)`, which has the size of 446 bytes, and `Partition Table(PT)`, which is able to record only 4 records.

```bash
# the composition of first sector, which consist of the first sectors of cylinders from 1~100
|--------|----------|------------|------------|-------------|
| MBR&PT | 1 -- 100 | 101 -- 200 | 201 -- 300 | 301 -- 400  |
|________|__________|____________|____________|_____________|

PT(64 bytes) -> P1: 1 -- 100, P2: 101 -- 200,
                P3: 201 -- 300, P4: 301 -- 400.

# Given filename of device is /dev/hda, then
P1: /dev/hda1    P2: /dev/hda2
P3: /dev/hda3    P4: /dev/hda4
```

- `Partitions`: there are three partitions, `primary partition`, `extented partitions` and `logical partitions`. # of primary and extended partitions is no more than 4, and there is 1 extended partition at most.

```bash
         | Primary  | <---------     Extended     --------> |
|--------|----------|------------|------------|-------------|
| MBR&PT | 1 -- 100 | 101 -- 200 | 201 -- 300 | 301 -- 400  |
|________|__________|____________|____________|_____________|
             P1          P2           P3            P4

# also we could divide extended partition into more than 3 partitions by using one of a sector in P2 as a extended partition table,
| <--- Primary ---> | <---------     Extended     --------> |
|--------|----------|----|----------------------------------|
| MBR&PT | 1 -- 100 | PT |          101 -- 400              |
|________|__________|____|__________________________________|
             P1                      P2
P3 = P4 = NULL

# then P2 could be divided into 5 logical partition,
         | Primary  | <---------     Extended     --------> |
|--------|----------|----|------|------|------|------|------|
| MBR&PT | 1 -- 100 | PT |  L1  |  L2  |  L3  |  L4  |  L5  |
|________|__________|____|______|______|______|______|______|
                                 Logic Partition
             P1                       P2
P1: /dev/hda1   P2: /dev/hda2   # hda[3-4] is reserved for P3/4
L1: /dev/hda5   L2: /dev/hda6
L3: /dev/hda7   L4: /dev/hda8   L5: /dev/hda9
```

- The startup of a computer consists of
    - `Basic I/O System(BIOS)`: BIOS is firmware used to perform hardware initialization during the booting process.
    - `MBR`: is a special type of boot sector at the very beginning of partitioned computer mass storage devices like fixed disks or removable drives.
    - `Boot Loader`: loads programs of operation system.
    - `Shell`: loads shell programs.

## Ext2 File System

### File System

In computing, a file system controls how data is stored or retrieved. Without a file system, data placed in a storage medium would be one large body of data with no way to tell where one piece of data stops and the next begins. By separating the data into pieces and giving each piece a name, the data is easily isolated and identified. 

#### FAT and Ext2

The family of `FAT` file systems is supported by almost all operating systems for personal computers, including all versions of Windows and PC-DOS. 

The `Ext2`(Second Extended File System) is a file system for the Linux kernel. The space in Ext2 is split up into `blocks`. These blocks are grouped into block groups, analogous to cylinder groups in the Unix File System. There are typically thousands of blocks on a large file system. Data for any given file is typically contained within a single `block group` where possible. This is done to minimize the number of disk seeks when reading large amounts of contiguous data.

Each block group contains a copy of `the superblock` and `block group descriptor table`, and all block groups contain `a block bitmap`, `an inode bitmap`, `an inode table`, and finally `the actual data blocks`.

- `Super Block`: contains important information that is crucial to the booting of the operating system, which record the status of blocks and inodes, used and remained, the size of inode and block and so on.
- `Inode`: every file or directory is represented by an inode. The term "inode" comes from "index node". The inode includes data about the size, permission, ownership, and location on disk of the file or directory.
- `Block`: is the minimum unit that the data will be stored, usually 1K, 2K or 4K. When using 1K as the size of unit, the total number of block will be too large, so slowing down the speed of read and write. While using 4K, storage could be wasted when there are too many files smaller than 4K given **one block only saves one file**. Therefore the size of block is the matter of trade off between the use of storage and the speed of R/W.
- `File System Description`: describes the beginning and end of a block group, and important information of that group(superblock, bitmap, inodemap, datablock).
- `Block Bitmap`: records which block is used or unused.
- `Inode Bitmap`: records which inode is used or unused.

![Ext2: Indexed Allocation File System](codehome/src/img/linux/ext2.png)

| Block Size | Maximum Size of a File | Maximum Size of FS |
|:----:|:----:|:----:|
| 1KB | 16GB | 2TB |
| 2KB | 256GB | 8TB |
| 4KB | 2TB | 16TB |

- Noting: the size of inode is 128 bytes, including 12 direct records. So the system will use some block as the block pointers to indirect data blocks or double indirect ones. Assuming the size of block equals 1K, `12 * 1K + 256 * 1K + 256 * 256 * 1K = 16GB`, where a block is able to record information of 256 blocks given the size of a record is 4 bytes, `1K = 1024 bytes / 4 bytes = 256`.

#### The Difference Between Two FSs

`Ext2` is an `indexed allocation file system`, however `FAT` is a file system a little bit like link list.

```markdown
# In Ext2, inode is a data table recording where the data is stored.
inode: |---|---|---|---|-----|-----|
       |_1_|_2_|_3_|_4_|_..._|_100_|

blocks: |---|---|---|---|-----|----|
        |_1_|_2_|_3_|_4_|_..._|_50_|
        |----|----|----|----|-----|-----|
        |_51_|_52_|_53_|_54_|_..._|_100_|
        ......

inode(1): 2-37-48-79
inode(2): 44-3-28-76-4
....

block(1): | data |
block(2): | data |
....
#                     |- block(x)
# so file == inode -> |- block(y)
#                     |- block(z)

# However, in FAT, there is no inode, only blocks, and the blocks is organized as link list.

blocks: |---|---|---|---|-----|----|
        |_1_|_2_|_3_|_4_|_..._|_50_|
        |----|----|----|----|-----|-----|
        |_51_|_52_|_53_|_54_|_..._|_100_|
        ......

block(n): | current data | ptr to next data |
# file == block(x) -> block(y) -> block(z)
```

Let's have a try.

```bash
[root@localhost ~]$ df
Filesystem     1K-blocks    Used Available Use% Mounted on
/dev/vda1       41151808 2939012  36099364   8% /
devtmpfs          930772       0    930772   0% /dev
tmpfs             941368       0    941368   0% /dev/shm 

[root@localhost ~]$ dumpe2fs /dev/vda1
Filesystem volume name:    <none>              
Last mounted on:          /
Filesystem UUID:          b98386f1-e6a8-44e3-9ce1-a50e59d9a170
Filesystem magic number:  0xEF53
Filesystem revision #:    1 (dynamic)
Filesystem features:      has_journal ext_attr resize_inode dir_index filetype needs_recovery extent flex_bg sparse_super large_file huge_file uninit_bg dir_nlink extra_isize
Filesystem flags:         signed_directory_hash 
Default mount options:    user_xattr acl
Filesystem state:         clean
Errors behavior:          Continue
Filesystem OS type:       Linux
Inode count:              2621440
Block count:              10485248
Reserved block count:     524262
Free blocks:              8097464
Free inodes:              2397705
First block:              0
Block size:               4096
Fragment size:            4096
Reserved GDT blocks:      1021
Blocks per group:         32768
Fragments per group:      32768
Inodes per group:         8192
Inode blocks per group:   512
....
Group 0: (Blocks 0-32767) [ITABLE_ZEROED]
  Checksum 0x2ed9, unused inodes 2987
  Primary superblock at 0, Group descriptors at 1-3
  Reserved GDT blocks at 4-1024
  Block bitmap at 1025 (+1025), Inode bitmap at 1041 (+1041)
  Inode table at 1057-1568 (+1057)
  20046 free blocks, 3004 free inodes, 885 directories, 2987 unused inodes
  Free blocks: 10452, 12723-32767
  Free inodes: 1166, 1169, 1171, 1173, 1176, 1179, 1182, 1184, 1186-1187, 1191, 3415-3420, 5206-8192
Group 1: (Blocks 32768-65535) [INODE_UNINIT, ITABLE_ZEROED]
  Checksum 0x2d79, unused inodes 8192
  Backup superblock at 32768, Group descriptors at 32769-32771
  Reserved GDT blocks at 32772-33792
  Block bitmap at 1026 (bg #0 + 1026), Inode bitmap at 1042 (bg #0 + 1042)
  Inode table at 1569-2080 (bg #0 + 1569)
  0 free blocks, 8192 free inodes, 0 directories, 8192 unused inodes
  Free blocks: 
  Free inodes: 8193-16384
```

### Ext2 and Directory

When making a directory, Ext2 File System will allocate one inode and at least one block to the directory, where inode saves the attributes of that directory(permission, owner and so forth) and the number of allocated block. And the block will record the name of the file in that directory and its inode. 

```markdown
inode: owner, permission, group, inode of allocated block ...
block: filename1, inode1
       filename2, inode2
       filename3, inode3
       ...
```

- That's why when rename a file, we must have write permission of the directory where the file is.

```bash
[root@localhost ~]$ ll -d / /usr/bin /boot /home
dr-xr-xr-x. 18 root root 4.0K Aug  6 22:34 /           # a 4K block
dr-xr-xr-x.  5 root root 4.0K Nov 29  2018 /boot       # a 4K block
drwxr-xr-x.  4 root root 4.0K Aug  7 10:15 /home       # a 4K block
dr-xr-xr-x.  2 root root  20K Sep  8 15:23 /usr/bin    # 5 4K blocks
```

### Ext2 and Files

When creating a file, Ext2 File System will allocate one inode and *N* blocks corresponding to its size. Given a file with the size of 100KB, file system will give an inode and `25 + 1` blocks to store that file, where `1` block serves as a table recording the other 25 blocks which store data of the file.

### Location of a File

Given the knowledge above, we will figure out how the system read a file,

```bash
[root@localhost ~]$ df
Filesystem     1K-blocks    Used Available Use% Mounted on
/dev/vda1       41151808 2939012  36099364   8% /
devtmpfs          930772       0    930772   0% /dev
tmpfs             941368       0    941368   0% /dev/shm 

[root@localhost ~]$ ll -di / /etc/ /etc/passwd 
      2 dr-xr-xr-x. 18 root root 4.0K Aug  6 22:34 /
1048577 drwxr-xr-x. 81 root root 4.0K Sep  8 15:23 /etc/
1066290 -rw-r--r--   1 root root 1.2K Aug  7 10:15 /etc/passwd  

# 1. we are able to get the inode of `/` from mounting information from `/dev/vda1`, which is 2, so we get the number of `/`'s block, given that we have `r,x` permission.
# 2. in the block, we find the inode of directory `etc/`, 1048577.
# 3. in the inode of `etc/`, user with `r,x` permission could read the content of `etc/`, that is `etc/`'s block.
# 4. in the block, we find the inode of file passwd, 1066290.
# 5. then user could read the content of passwd, or in other word, access blocks of passwd, given the user has `r` permission.
```

### Ext2/Ext3 Journaling File System

What happened when a user touch a file? 

- check if the user has `w, x` permission of that directory.
- find available inode in inode bitmap, and write the permission of new file.
- access unused blocks in block bitmap and write data into them, meanwhile update inode information.
- update the status of inode bitmap and block bitmap.

In general, inode table and data block are called `data storage area`, super block, block bitmap and inode bitmap are named `metadata`, which are likely to change.

However, there is a scenario that something inconsistent happened. for example, for some reasons, in the final step, the inode bitmap and block bitmap have not been updated. Alas, that's a crisis.

So, computer scientist come up with an idea of `journaling file system`. They allocate some blocks to record the change of file system. There are mainly three steps,

- preparation: when writing a file, the system will write the information of new file into journal file.
- process: write the permission and data of a new file and update metadata.
- end: after finishing updating metadata, the system will record in the journal file.

What a great idea.

```bash
[root@localhost ~]$ dumpe2fs /dev/vda1
...
Journal inode:            8
First orphan inode:       660494
Default directory hash:   half_md4
Directory Hash Seed:      64c050c5-05fb-4ed0-9f92-f5abefc12cc4
Journal backup:           inode blocks
Journal features:         journal_incompat_revoke
Journal size:             128M
Journal length:           32768
Journal sequence:         0x0002c351
Journal start:            1952
...

# 32768 blocks * 4K = 128MB
```

### Mount Point

`Mount` is the way of OS to link file system and directory tree. The point is that **mount point must be a directory, which is the entrance of file system**.

```bash
[root@localhost ~]$ ll -di /
      2 dr-xr-xr-x. 18 root root 4.0K Aug  6 22:34 /

# in general, # of inode of top directory is 2.
```

TIP: `/`, `/.` and `/..` are the same thing for they have the same inode number.

```bash
[root@localhost ~]$ ls -ild / /. /..                
2 dr-xr-xr-x. 18 root root 4096 Aug  6 22:34 /
2 dr-xr-xr-x. 18 root root 4096 Aug  6 22:34 /.  
2 dr-xr-xr-x. 18 root root 4096 Aug  6 22:34 /..
```

## Related Command

- `df` or `du`
`df` and `du`, which can be seen as *disk free* and *disk usage* respectively, are used to report file system disk space usage.

```bash
df [-hi]
# where,
# -h: print sizes in human readable format (e.g., 1K 234M 2G)
# -i: list inode information instead of block usage

[root@localhost ~]$ df
Filesystem     1K-blocks    Used Available Use% Mounted on
/dev/vda1       41151808 2939196  36099180   8% /
devtmpfs          930772       0    930772   0% /dev

[root@localhost ~]$ df -h
Filesystem      Size  Used Avail Use% Mounted on 
/dev/vda1        40G  2.9G   35G   8% /
devtmpfs        909M     0  909M   0% /dev  

[root@localhost ~]$ df -i
Filesystem      Inodes IUsed   IFree IUse% Mounted on 
/dev/vda1      2621440 77295 2544145    3% / 
devtmpfs        232693   327  232366    1% /dev

```

```bash
du -[sm] (directory)
# where,
# -s: display only a total for each argument
# -m: like --block-size=1M

[root@localhost ~]$ du -sm /*
0       /bin
128     /boot
0       /dev
33      /etc
1       /home
0       /lib
0       /lib64
1       /lost+found
1       /media
1       /mnt
1       /opt
0       /proc
404     /root
1       /run
0       /sbin
1       /srv
0       /sys
78      /tmp
1798    /usr
356     /var

# `/proc` is mounted in memory, so don't worry that it will show 0
```

- `ln` link file
`ln` is used to make links between files.

### Hard Link

`hard link`: two files have the same inode. As the matter of fact, they are the same file. So the nature of making a hard link is to associate the inode of a file to other directory. Take `crontab` file for example. `/etc/crontab` and `/root/crontab` are the same file, but they have 2 records in directory `etc/` and `root/` respectively. In other word, there are 2 ways to access `crontab` through directory tree.

```bash
[root@localhost ~] ln /etc/crontab .  # in root directory
[root@localhost ~] ll -i /etc/crontab /root/crontab
1057705 -rw-r--r--. 2 root root 451 Jun 10  2014 /etc/crontab
1057705 -rw-r--r--. 2 root root 451 Jun 10  2014 /root/crontab  

# `/` -> `etc/` -> `crontab` or `/` -> `root/` -> `crontab`
```

When making a hard link, the number of inode and block won't change, the ONLY thing change are *the content of directory block* and *index number(+1)*. **All directory containing inode of that file have the same level of previlege.**

What happened when filename is deleted? The answer is that the file is not deleted, what's deleted is the record to the file in that directory block. **Therefore, when index number > 0, the file always exists**.

```bash
[root@localhost ~] rm /root/crontab
[root@localhost ~] ll -i /etc/crontab /root/crontab
ls: cannot access /root/crontab: No such file or directory
1057705 -rw-r--r--. 1 root root 451 Jun 10  2014 /etc/crontab
```

### Symbolick Link

`symbolic link` also termed `soft link`: is a special kind of file that points to another file, much like a shortcut in Windows or a Macintosh alias. Unlike a hard link, a symbolic link does not contain the data in the target file. It simply points to another entry somewhere in the file system. They are totally two different files since they have different inodes.

```bash
[root@localhost ~] ln -s /etc/crontab crontab-shortcut  # in root directory
[root@localhost ~] ll -i /etc/crontab /root/crontab-shortcut
1057705 -rw-r--r--. 1 root root 451 Jun 10  2014 /etc/crontab
 269698 lrwxrwxrwx  1 root root  12 Nov 22 15:07 /root/crontab-shortcut -> /etc/crontab

# why 12 bytes? the string of `/etc/crontab` contains 12 alphabets, each of which is 1 byte.
# `/` -> `root/` -> `contab-shortcut` -> `etc/` -> `crontab`.
```

```bash
ln -[sf] (origin) (destination)
# where,
# -s: make symbolic links instead of hard links.
# -f, --force: remove existing destination files.
```

QUESTION: When making a directory, how does the index number change?
ANSWER: Index number of new directory is 2 (new directory itself and `new-directory/.`), and index number of its parent directory plus 1 (`new-directory/..`).

```bash
[root@localhost ~] ll -di /root
262145 dr-xr-x---. 13 root root 4.0K Nov 22 15:25 .
[root@localhost ~] mkdir helloworld
[root@localhost ~] ll -di /root /root/helloworld
262145 dr-xr-x---. 14 root root 4.0K Nov 22 15:27 .      # plus 1 since `helloworld/..`
658222 drwxr-xr-x   2 root root 4.0K Nov 22 15:26 ./helloworld
```

### Partition and Format

- `fdisk`
`fdisk` is used to manipulate disk partition table.

```bash
[root@localhost ~] df /    # to find device filename
Filesystem     1K-blocks    Used Available Use% Mounted on
/dev/vda1       41151808 2939244  36099132   8% /

[root@localhost ~] fdisk /dev/vda  # without number
Welcome to fdisk (util-linux 2.23.2).

Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

Command (m for help): m

Command action
   a   toggle a bootable flag
   b   edit bsd disklabel
   c   toggle the dos compatibility flag
   d   delete a partition
   g   create a new empty GPT partition table
   G   create an IRIX (SGI) partition table
   l   list known partition types
   m   print this menu
   n   add a new partition
   o   create a new empty DOS partition table
   p   print the partition table
   q   quit without saving changes
   s   create a new empty Sun disklabel
   t   change a partition system id
   u   change display/entry units
   v   verify the partition table
   w   write table to disk and exit
   x   extra functionality (experts only)
```

```bash
Command (m for help): p

Disk /dev/vda: 42.9 GB, 42949672960 bytes, 83886080 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x000a57df

   Device Boot      Start         End      Blocks   Id  System
/dev/vda1   *        2048    83884031    41940992   83  Linux
```

Now let's start to partition.

```bash
# deleted current partition
Command (m for help): d
Selected partition 1
Partition 1 is deleted

Command (m for help): p

Disk /dev/vda: 42.9 GB, 42949672960 bytes, 83886080 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x000a57df

   Device Boot      Start         End      Blocks   Id  System

# create a primary partition
Command (m for help): n
Partition type:
   p   primary (0 primary, 0 extended, 4 free)
   e   extended

Select (default p): p
Partition number (1-4, default 1): 2
First sector (2048-83886079, default 2048): 
Using default value 2048
Last sector, +sectors or +size{K,M,G} (2048-83886079, default 83886079): +512M
Partition 2 of type Linux and of size 512 MiB is set

Command (m for help): p

Disk /dev/vda: 42.9 GB, 42949672960 bytes, 83886080 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x000a57df

   Device Boot      Start         End      Blocks   Id  System
/dev/vda2            2048     1050623      524288   83  Linux

# add an extended partition
Command (m for help): n
Partition type:
   p   primary (1 primary, 0 extended, 3 free)
   e   extended
Select (default p): e
Partition number (1,3,4, default 1): 3
First sector (1050624-83886079, default 1050624): 
Using default value 1050624
Last sector, +sectors or +size{K,M,G} (1050624-83886079, default 83886079): 
Using default value 83886079
Partition 3 of type Extended and of size 39.5 GiB is set

Command (m for help): p

Disk /dev/vda: 42.9 GB, 42949672960 bytes, 83886080 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x000a57df

   Device Boot      Start         End      Blocks   Id  System
/dev/vda2            2048     1050623      524288   83  Linux
/dev/vda3         1050624    83886079    41417728    5  Extended

# add a logical partition
Command (m for help): n
Partition type:
   p   primary (1 primary, 1 extended, 2 free)
   l   logical (numbered from 5)
Select (default p): l
Adding logical partition 5
First sector (1052672-83886079, default 1052672): 
Using default value 1052672
Last sector, +sectors or +size{K,M,G} (1052672-83886079, default 83886079): +2048M
Partition 5 of type Linux and of size 2 GiB is set

Command (m for help): p

Disk /dev/vda: 42.9 GB, 42949672960 bytes, 83886080 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x000a57df

   Device Boot      Start         End      Blocks   Id  System
/dev/vda2            2048     1050623      524288   83  Linux
/dev/vda3         1050624    83886079    41417728    5  Extended
/dev/vda5         1052672     5246975     2097152   83  Linux
```

- `mkfs`
`mkfs` is used to build a Linux filesystem on a device, usually a hard disk partition.

```bash
mkfs -t (file system) (device filename)
# where,
# -t: specify  the  type  of  filesystem to be built, ext3, ext2, vfat ...
```

### Mount Command

- `mount`
`mount` serves to attach the filesystem found on some device to the big file tree.

```bash
mount -t (file system) (device filename) (directory)
# where,
# -t: specify  the  type  of  filesystem to be built, ext3, ext2, vfat ...

[root@localhost ~] mkdir /mnt/vda5
[root@localhost ~] mount /dev/vda5 /mnt/vda5
[root@localhost ~] df /dev/vda
Filesystem     1K-blocks    Used Available Use% Mounted on
/dev/vda1       41151808 2939244  36099132   8% /
/dev/vda5       21251918  182738   4939117   2% /mnt/vda5
```

- `umount`
`umount` command detaches the file system(s) mentioned from the file hierarchy.

```bash
umount (device filename)

[root@localhost ~] umount /dev/vda5
```

- `/etc/fstab` and `/etc/mtab`
These two files are reserved for configuring mount automatically.

```bash
[root@localhost ~] cat /etc/fstab 
# device  mount point   filesystem   parameters   dump    fsck             
minzhq         /           ext4       defaults     1        1
/dev/vda5  /mnt/vda5       ext3       defaults     1        2

# dump means if backup, 1 for backup everyday, 0 for no backup.
# fsck means filesystem check, 0 for no check, 1 check at the beginning, 2 check but later.  
```

<EndMarkdown>