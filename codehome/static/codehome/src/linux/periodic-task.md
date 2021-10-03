# Periodic Task

## Table of Contents
- [Introduction](#introduction)
- [At](#at)
- [Cron](#cron)
	- [Permission](#permission)
	- [Crontab](#crontab)
	- [System Scheduling Task](#systemschedulingtask)
	- [Scheduling Directory](#schedulingdirectory)
	- [Anacron](#anacron)

<TableEndMark>

## Introduction

Whenever using a UNIX-based operating system, certain tasks are to be performed repeatedly. Running them manually every single time is time-consuming and overall inefficient. To solve this issue, UNIX comes with its built-in task schedulers. These task schedulers act like a smart alarm clock. When the alarm goes off, the operating system will run the predefined task.

In the case of Linux, it comes with two basic but powerful tools: Cron daemon (default task scheduler) and at (more suitable for one-time task scheduling).

## At

- `at` 
`at` offers the ability to run a command/script at a specific time or at a fixed interval, note that `at` will run the target job once whereas `cron` would re-run the job at the interval. The `at` tool is less popular compared to cron, but it’s relatively easier to use. You can use certain keywords like midnight or teatime 

Before our experiment, let's start `atd` service.

```bash
# IF at service is installed, ignore following commands
[root@localhost ~] yum install -y at
[root@localhost ~] systemctl status atd
   Loaded: loaded (/usr/lib/systemd/system/atd.service; enabled; vendor preset: enabled)
   Active: inactive (dead)
[root@localhost ~] systemctl start atd
[root@localhost ~] systemctl status atd
 Loaded: loaded (/usr/lib/systemd/system/atd.service; enabled; vendor preset: enabled)
   Active: active (running) since Wed 2021-03-17 15:16:26 CST; 3s ago
 Main PID: 2015 (atd)

# time for syntax of at
at [-mldvc] TIME
# where,
# -m: mail user after executing scheduling task
# -l: display all at tasks, which is equal to `atq`
# -d: delete a task in at queue, which is equal to `atrm`
# -v: display in time format
# -c: show detailed command of a task
# TIME:
# HH:MM     ex> 04:00
# HH:MM YYYY-MM-DD    ex> 09:31 1995-12-21
# HH:MM[am/pm] [Month] [Date]    ex> 04pm March 17
# HH:MM[am/pm] + number[minutes/hours/days/weeks]
# ex> now + 5 days
```

```bash
[root@localhost ~] at now + 5 minutes 
at> echo -e "Hello world"
at> <EOT> # Ctrl + d
job 1 at Wed Mar 17 15:31:00 2021
[root@localhost ~] at -c 1
#!/bin/sh
# atrun uid=0 gid=0
# mail root 0
umask 22
...
echo -e "Hello world"

[root@localhost ~] atq
1       Wed Mar 17 15:31:00 2021 a root
[root@localhost ~] atrm 1
[root@localhost ~] atq
```

When comes to `at`, we have to talk about `batch`.

- `batch`
`batch` is a command based on `at`. It will execute scheduling tasks when CPU load is less than 0.8, that is when it is not too busy. It has the same usage of `at`.

```bash
[root@localhost ~] batch 23:00 2020-12-21
at> sync
at> sync
at> shutdown -h now
at> <EOT>
[root@localhost ~] atq
1       Wed Dec 21 23:00:00 2020 b root
```

## Cron

- `cron`
`cron` is used to scheduling a task in linux, for example, regular backups that occur daily at 2 a.m.

The `crond` daemon is the background service that enables `cron` functionality.

The cron service checks for files in the `/var/spool/cron` and `/etc/cron.d` directories and the `/etc/anacrontab` file. The contents of these files define cron jobs that are to be run at various intervals. The individual user cron files are located in `/var/spool/cron`, and system services and applications generally add cron job files in the `/etc/cron.d` directory. The `/etc/anacrontab` is a special case that will be covered later.

### Permission

The first question is who is able to use cron service. There are two files specify that.

- `/etc/cron.allow`: if the file exists, only the users listed in the file will be allowed to use cron service.
- `/etc/cron.deny`: if the file exists, the users listed in the file will be denied to access cron service. Its priority is lower than `cron.allow`.

### Crontab

When a user use `crontab` to create a scheduling task, it will be recorded into `/var/spool/cron/` and the owner will be marked too. For example, if Brain use `crontab` to create a task, it will be recorded into `/var/spool/cron/brain`.

WARNING: do NOT edit cron file with `vi`, syntax error will damage normal cron service.

```bash
crontab [-u username, -l | -e | -r]
# where,
# -u: used by root to schedule task for other users
# -e: edit the content of crontab
# -l: list the content of crontab
# -r: clear the content of crontab
```

```bash
# For root
[root@localhost ~] cat /etc/crontab
SHELL=/bin/bash                                                         
PATH=/sbin:/bin:/usr/sbin:/usr/bin                                      
MAILTO=root                                                             
                                                                        
# For details see man 4 crontabs                                        
                                                                        
# Example of job definition:                                            
# .---------------- minute (0 - 59)                                     
# |  .------------- hour (0 - 23)                                       
# |  |  .---------- day of month (1 - 31)                               
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...               
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat                                                          
# |  |  |  |  |
# *  *  *  *  * user-name  command to be executed

# execute sync every 30 minutes
*/30 * * * * root /bin/sync


# For normal user, notice that the user name is not needed
[MinzhiQu@localhost ~] crontab -e
# Example of job definition:                                            
# .---------------- minute (0 - 59)                                     
# |  .------------- hour (0 - 23)                                       
# |  |  .---------- day of month (1 - 31)                               
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...               
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat                                                          
# |  |  |  |  |
# *  *  *  *  *  command to be executed

# send message at 23:59 12-20 every year
59 23 20 12 * echo -e "Happy Birthday"

[MinzhiQu@localhost ~] crontab -r
[MinzhiQu@localhost ~] crontab -l
no crontab for MinzhiQu
```

### System Scheduling Task

Notice that in `/etc` directory, there are some files and directories related to `cron` -- `/etc/cron.hourly/`, `/etc/cron.daily/`, `/etc/cron.monthly/`, and `/etc/cron.weekly`. For scheduling system task, just put `*.sh` into responding directory.

```bash
[root@localhost ~] cat /etc/crontab
SHELL=/bin/bash                                                         
PATH=/sbin:/bin:/usr/sbin:/usr/bin                                      
MAILTO=root    # when error occurs, it will mail root
...
```

### Scheduling Directory

We are able to create a directory which has the same function as `cron.hourly` as a normal user with `run-parts` argument.

```bash
[MinzhiQu@localhost ~] mkdir /MinzhiQu/runcron
[MinzhiQu@localhost ~] crontab -e
*/10 * * * * root run-parts /MinzhiQu/runcron
```

### Anacron

`anacron` is a computer program that performs periodic command scheduling, which is traditionally done by cron, but without assuming that the system is running continuously. Thus, it can be used to control the execution of daily, weekly, and monthly jobs (or anything with a period of n days) on systems that don't run 24 hours a day. 

```bash
[root@localhost ~] ll /etc/cron.*/*ana*
-rwxr-xr-x. 1 root root 392 Aug  9  2019 /etc/cron.hourly/0anacron
[root@localhost ~] cat /etc/cron.hourly/0anacron
#!/bin/sh
# Check whether 0anacron was run today already
if test -r /var/spool/anacron/cron.daily; then
    day=`cat /var/spool/anacron/cron.daily`
fi
if [ `date +%Y%m%d` = "$day" ]; then
    exit 0;
fi

# Do not run jobs when on battery power
if test -x /usr/bin/on_ac_power; then
    /usr/bin/on_ac_power >/dev/null 2>&1
    if test $? -eq 1; then
    exit 0
    fi
fi
/usr/sbin/anacron -s
```

Notice that `0anacron` file appears in `/etc/cron.hourly`, hence it will be executed hourly.

What `0anacron` does is just update timestamp. It serves as a benchmark for `anacrontab` to check if a scheduling task is executed normally, and if not, it will be added to jobs and be executed later.

<EndMarkdown>