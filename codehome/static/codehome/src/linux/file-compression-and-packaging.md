# File Compressing and Packaging

## Table of Contents
- [Compression](#compression)
- [Compression Command](#compressioncommand)
- [Packaging Command](#packagingcommand)
- [Backup and Restore](#backupandrestore)
	- [Backup](#backup)
		- [Backup a File System](#backupafilesystem)
		- [Backup a Directory](#backupadirectory)
	- [Restore](#restore)

<TableEndMark>

## Compression

If you downloaded many programs and files off the Internet, you've probably encountered ZIP file before. This compression technology is a very handy invention, especially for web users, because it let's you reduce the overall number of bits and bytes in a file so it can be transmitted faster over slower Internet connections, or take up less space on a disk.

At first glance, this seems mysterious. How can you reduce the number of bits or bytes of a file and then add these exact bits back later?

In fact, most types of computer files are fairly redundant -- they have the same information listed over and over again. The task of file compression programs is to get rid of the redundancy. For example, there are many consecutive 0 or 1 in the binary file. Instead of storing them as they were, the compression program will store them in a smart way -- they could record 100 consecutive 1s as `1001`, which means there are a hundred 1 so that 100-bits data could be reduced or compressed into 4 bits data.

On a Linux machine, there are 3 common compression commands(`compress`, `gzip`, and `bzip2`) and 1 critical packaging command(`tar`).

## Compression Command

- `Compress`
`Compress` reduces the size of the named files using adaptive Lempel-Ziv coding. Whenever possible, each file is replaced by one with the extension .Z, while keeping the same ownership modes, access and modification times. **BTW, this is a old and less popular compressing command**.

```bash
compress [-rcv] (file/directory)
# where,
# -r: compress will operate recursively.
# -c: makes compress/uncompress write to the standard output, and no  files are changed.
# -v: prints its version and patchlevel, along compressing information.
```

- `gzip` and `zcat`
`gzip` reduces the size of the named files using Lempel-Ziv codin (LZ77). Whenever possible, each file is replaced by one with the extension .gz, while keeping the same ownership modes, access and modification times.

```bash
gzip [-cdtv] (filename)
# where,
# -c: writes output on standard output; keep original files unchanged. 
# -d: decompress. 
# -t: checks the compressed file integrity.
# -v: displays the name and percentage reduction for each file compressed or decompressed.

[root@localhost ~] ls
man_db.conf
[root@localhost ~] gzip -v man_db.conf 
man_db.conf:     61.9% -- replaced with man_db.conf.gz
# after compressing
[root@localhost ~] ls
man_db.conf.gz
```

`zcat` is used to access the content of compressed file without decompressing it.

```bash
[root@localhost ~] zcat man_db.conf.gz
...
# tabs or spaces may be used as `whitespace' separators.
#
# There are three mappings allowed in this file:
# --------------------------------------------------------
# MANDATORY_MANPATH                     manpath_element
# MANPATH_MAP           path_element    manpath_element
# MANDB_MAP             global_manpath  [relative_catpath]
#---------------------------------------------------------
# every automatically generated MANPATH includes these fields
...
```

- `bzip2` and `bzcat`
`bzip2` compresses files using the Burrows-Wheeler block sorting text compression algorithm, and Huffman coding.

```bash
bzip2 [-cdkv] (filename)
# where,
# -c: writes output on standard output; keep original files unchanged. 
# -d: decompress.
# -k: keep original files. 
# -v: displays the name and percentage reduction for each file compressed or decompressed.

[root@localhost ~] ls
man_db.conf
[root@localhost ~] bzip2 -v man_db.conf
man_db.conf:  2.604:1,  3.073 bits/byte, 61.59% saved, 5171 in, 1986 out.
[root@localhost ~] ls
man_db.conf.bz2
```

Similarly, `bzcat` is used to access the content of compressed files.

## Packaging Command

- `tar` saves many files together into a single tape or disk archive, and can restore individual files from the archive.

```bash
tar -[jz(c/t/x)v] (-f destination) (origin)
# where,
# -j: filter the archive through bzip2.
# -z: filter the archive through gzip.
# -c: create a new archive.
# -t: list the contents of an archive.
# -x, --extract: extract files from an archive.
# -v: verbosely list files processed.
# -f: use archive file or device ARCHIVE.
# -C: extracted in specific directory.

# backup argument
# -p: preserves permissions.
# -P: don't strip leading `/'s from file names.
```

```bash
# common operation
[root@localhost ~] mkdir test
[root@localhost ~] touch test/test1 test/test2
[root@localhost ~] tar -zcv -f test
[root@localhost ~] tar -zcvf test.tar.gz test
[root@localhost ~] ls
test  test.tar.gz

# backup operation
[root@localhost ~] tar -zpcv -f /root/etc.tar.gz /etc
tar: Removing leading '/' from member names
/etc/
/etc/shadow-
/etc/ethertypes
/etc/ppp/
/etc/ppp/peers/
/etc/ppp/ipv6-down
/etc/ppp/ip-up
/etc/ppp/ipv6-up
/etc/ppp/ip-down
/etc/ppp/ip-down.ipv6to4
...
# '/' has been removed

[root@localhost ~] tar -ztv -f /root/etc.tar.gz
-rw------- root/root         0 2018-11-29 11:34 etc/crypttab
-rw-r--r-- root/root       216 2018-04-12 00:10 etc/sestatus.conf
-rw-r----- root/root      1786 2018-06-27 02:07 etc/sudo.conf
-rw-r--r-- root/root       623 2018-12-03 11:09 etc/sysctl.conf
lrwxrwxrwx root/root         0 2018-11-29 11:38 etc/redhat-release -> centos-release
drwxr-x--- root/root         0 2018-11-29 11:38 etc/audit/
drwxr-x--- root/root         0 2018-08-16 22:39 etc/audit/rules.d/
# noting that '/' before 'etc' has been removed
# why to remove leading '/'? the answer is for security.
# when extracting etc.tar.gz, given in '/tmp/' directory, the path of
# extracted files would be '/tmp/etc/...'. However, if leading '/' is
# preserved, the path of extracted files would be '/etc/...', which 
# will replace the original '/etc/...'.

[root@localhost ~] ls
etc.tar.gz
[root@localhost ~] tar -jpcv -f /root/etc.tar.bz2 /etc
[root@localhost ~] ll etc.tar.*
-rw-r--r-- 1 root root 8.3M Nov 29 08:50 etc.tar.bz2
-rw-r--r-- 1 root root 9.4M Nov 29 08:47 etc.tar.gz
[root@localhost ~] du -sm /etc
33      /etc
# disk usage: bz2 < gz < original files

# the file will be extracted into '/tmp' instead of current directory
[root@localhost ~] tar -zxvf etc.tar.gz -C /tmp 
etc/                     
etc/shadow- 
etc/ethertypes                    
etc/ppp/
etc/ppp/peers/
etc/ppp/ipv6-down
etc/ppp/ip-up
etc/ppp/ipv6-up 
etc/ppp/ip-down   

# --exclude: excludes files that should not be compressed
# create an archive of 'root', but exclude '/root/etc*' files
[root@localhost ~] tar -zcvf etc.tat.gz --exclude=/root/etc* /root

# what if I want to backup only newer files? using -newer argument
[root@localhost ~] tar -jcv -f /root/etc.newer.20181224.tar.bz2 --newer-mtime="2018/12/24" /etc/*
```

## Backup and Restore

Despite that `tar` command can be used to backup, there is a formal backup command in linux termed `dump`.

### Backup

- `dump`
`dump` examines files on an ext2/3/4 filesystem and determines which files need  to  be backed up. These files are copied to the given disk, tape or other storage medium for safe keeping.

The  **dump level** (any integer). A level 0, full backup, specified by -0 guarantees the entire file system is copied. A level  number above 0, incremental backup, tells dump to copy all files new or modified since the last dump of a lower level.

```bash
dump -[Suvj] -(level) -(f) (destination) (origin)
# where,
# -S: size estimate. Determine the amount of space that is needed to  perform the dump without actually doing it.
# -u: updates the  file  /etc/dumpdates  after  a  successful  dump.
# -v: makes dump to print extra information which could be helpful in debug sessions.
# -j: compresses every block to be written on  the  tape  using  bzlib  library.
# -f: writes the backup to file.
# --level: specifies a backup level.
```

#### Backup a File System

```bash
[root@localhost ~] df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda1        40G  2.9G   35G   8% /       
devtmpfs        909M     0  909M   0% /dev
tmpfs           920M     0  920M   0% /dev/shm
[root@localhost ~] dump -S /dev/vda1
3034057728
# about 2.84G

# backup '/' with dump in full backup level
[root@localhost ~] dump -0u -f system.dump /
  DUMP: Date of this level 0 dump: Sun Nov 29 10:10:14 2020 
  DUMP: Dumping /dev/vda1 (/) to system.dump                                                   
  DUMP: Label: none
  DUMP: Writing 10 Kilobyte records
  DUMP: mapping (Pass I) [regular files]
  DUMP: mapping (Pass II) [directories]
  DUMP: estimated 2962955 blocks.
  DUMP: Volume 1 started with block 1 at: Sun Nov 29 10:10:15 2020
  DUMP: dumping (Pass III) [directories]
  DUMP: dumping (Pass IV) [regular files]
  DUMP: Closing system.dump
  DUMP: Volume 1 completed at: Sun Nov 29 10:11:41 2020
  DUMP: Volume 1 2980690 blocks (2910.83MB)
  DUMP: Volume 1 took 0:01:26
  DUMP: Volume 1 transfer rate: 34659 kB/s
  DUMP: 2980690 blocks (2910.83MB) on 1 volume(s)
  DUMP: finished in 86 seconds, throughput 34659 kBytes/sec
  DUMP: Date of this level 0 dump: Sun Nov 29 10:10:14 2020
  DUMP: Date this dump completed:  Sun Nov 29 10:11:41 2020
  DUMP: Average transfer rate: 34659 kB/s
  DUMP: DUMP IS DONE

# done! backup record has been updated into dumpdates file
# NOTICE that -u will work on only when backuping an entire file system
[root@localhost ~] ll system.dump /etc/dumpdates
-rw-rw-r-- 1 root disk   43 Nov 29 10:11 /etc/dumpdates
-rw-r--r-- 1 root root 2.9G Nov 29 10:11 system.dump

# have a look at dumpdates
[root@localhost ~] cat /etc/dumpdates
/dev/vda1 0 Sun Nov 29 10:10:14 2020 +0800
# or
[root@localhost ~] dump -W
Last dump(s) done (Dump '>' file systems):
  /dev/vda1    ( /) Last dump: Level 0, Date Sun Nov 29 10:10:14 2020

# now let's try level 1, incremental backup
[root@localhost ~] touch newfile1 newfile2 newfile3
[root@localhost ~] dump -1u -f system.dump.1 / 
  DUMP: Date of this level 1 dump: Sun Nov 29 10:20:37 2020
  DUMP: Date of last level 0 dump: Sun Nov 29 10:10:14 2020
  DUMP: Dumping /dev/vda1 (/) to system.dump.1
  DUMP: Label: none
  DUMP: Writing 10 Kilobyte records
  DUMP: mapping (Pass I) [regular files]
  DUMP: mapping (Pass II) [directories]
  DUMP: estimated 3091292 blocks.
  DUMP: Volume 1 started with block 1 at: Sun Nov 29 10:20:40 2020
  DUMP: dumping (Pass III) [directories]
  DUMP: dumping (Pass IV) [regular files]
  DUMP: Closing system.dump.1
  DUMP: Volume 1 completed at: Sun Nov 29 10:21:39 2020
  DUMP: Volume 1 3091040 blocks (3018.59MB)
  DUMP: Volume 1 took 0:00:59
  DUMP: Volume 1 transfer rate: 52390 kB/s
  DUMP: 3091040 blocks (3018.59MB) on 1 volume(s)
  DUMP: finished in 59 seconds, throughput 52390 kBytes/sec
  DUMP: Date of this level 1 dump: Sun Nov 29 10:20:37 2020
  DUMP: Date this dump completed:  Sun Nov 29 10:21:39 2020
  DUMP: Average transfer rate: 52390 kB/s
  DUMP: DUMP IS DONE
[root@localhost ~] ll system.dump system.dump.1
-rw-r--r-- 1 root root 2.9G Nov 29 10:11 system.dump
-rw-r--r-- 1 root root 3.0G Nov 29 10:21 system.dump.1
[root@localhost ~] cat /etc/dumpdates 
/dev/vda1 0 Sun Nov 29 10:10:14 2020 +0800
/dev/vda1 1 Sun Nov 29 10:20:37 2020 +0800
[root@localhost ~] dump -W
  /dev/vda1    ( /) Last dump: Level 1, Date Sun Nov 29 10:20:37 2020
```

#### Backup a Directory

When backup a single directory, **only level 0 could be used**. Let's take `/etc` directory as example.

```bash
[root@localhost ~] dump -0j -f /root/etc.dump.bz2 /etc
  DUMP: Date of this level 0 dump: Sun Nov 29 10:30:10 2020
  DUMP: Dumping /dev/vda1 (/ (dir etc)) to /root/etc.dump.bz2
  DUMP: Label: none
  DUMP: Writing 10 Kilobyte records
  DUMP: Compressing output at compression level 2 (bzlib)
  DUMP: mapping (Pass I) [regular files]
  DUMP: mapping (Pass II) [directories]
  DUMP: estimated 35430 blocks.
  DUMP: Volume 1 started with block 1 at: Sun Nov 29 10:30:10 2020
  DUMP: dumping (Pass III) [directories]
  DUMP: dumping (Pass IV) [regular files]
  DUMP: Closing /root/etc.dump.bz2
  DUMP: Volume 1 completed at: Sun Nov 29 10:30:17 2020
  DUMP: Volume 1 took 0:00:07
  DUMP: Volume 1 transfer rate: 1638 kB/s
  DUMP: Volume 1 36670kB uncompressed, 11471kB compressed, 3.197:1
  DUMP: 36670 blocks (35.81MB) on 1 volume(s)
  DUMP: finished in 7 seconds, throughput 5238 kBytes/sec
  DUMP: Date of this level 0 dump: Sun Nov 29 10:30:10 2020
  DUMP: Date this dump completed:  Sun Nov 29 10:30:17 2020
  DUMP: Average transfer rate: 1638 kB/s
  # this line shows that some files has been compressed with bz2 lib
  DUMP: Wrote 36670kB uncompressed, 11471kB compressed, 3.197:1
  DUMP: DUMP IS DONE

# however we can't find record in dumpdates since `/etc` is not a full file system
[root@localhost ~] dump -W
  /dev/vda1    ( /) Last dump: Level 1, Date Sun Nov 29 10:20:37 2020
```

### Restore

- `restore`
`restore` command is used to restore files or file systems from backups made with `dump`.

```bash
restore -t [-f dumpfile]
restore -r [-f dumpfile]
# where,
# -t: the names of the specified files are listed if they occur on the backup.
# -r: restore (rebuild) a file system.

[root@localhost ~] restore -t -f /root/system.dump
   1320519      ./tmp/etc/ssh/ssh_host_dsa_key.pub
   1320520      ./tmp/etc/gcrypt
   1320521      ./tmp/etc/centos-release
   1320522      ./tmp/etc/init.d
   1320523      ./tmp/etc/kernel
   1320524      ./tmp/etc/kernel/postinst.d
   1320525      ./tmp/etc/kernel/postinst.d/51-dracut-rescue-postinst.sh
   1320526      ./tmp/etc/cron.deny
   ...
```

<EndMarkdown>