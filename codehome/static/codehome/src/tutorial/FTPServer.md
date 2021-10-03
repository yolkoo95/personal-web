# FTPServer 

## Table of Contents
- [Introduction](#introduction)
- [Working Principles](#workingprinciples)
- [FTP installation and configuration](#ftpinstallationandconfiguration)
	- [Preparations](#preparations)
		- [Install vsftpd through yum](#installvsftpdthroughyum)
		- [Related configuration files](#relatedconfigurationfiles)
	- [Basic Configuration of Anonymous FTP](#basicconfigurationofanonymousftp)
		- [Additional anonymous FTP configuration](#additionalanonymousftpconfiguration)
	- [Configuration of Security Group](#configurationofsecuritygroup)
		- [Add Security Group Rules for FTPServer](#addsecuritygrouprulesforftpserver)
	- [Configure Local User Login](#configurelocaluserlogin)
		- [Additional vsftpd.conf Parameters](#additionalvsftpd.confparameters)

<TableEndMark>

## Introduction

FTP is an acronym for File Transfer Protocol which is used for controlling two-way file transfer over the Internet. It is also an application. There are various FTP applications based on different operating systems, but all these applications utilize the same protocol for transferring files.Computers provide file storage and access services on the Internet through FTP. An FTP server is a server that supports FTP. FTP provides storage and transfer services.Download and Upload Downloading files is tantamount to duplicating files from the remote host to the client; and uploading files is duplicating files from the client to the remote host. In Internet language, a user can upload to and download from a remote host via a client program.

## Working Principles

FTP utilizes a client/server model (C/S architecture) to build a connection between a client and a server via TCP. Unlike most other application protocols, FTP builds two communication links: a control link and a data link, between a client and a server respectively. The control link is responsible for sending and receiving FTP commands during FTP sessions, and the data link is responsible for transferring data. An FTP session includes two channels: a control channel and a data channel. FTP has two working modes: the `active mode` and the `passive mode`. When in active mode, the server connects to the client actively. When in passive mode, the server waits for client connections.(For both active mode and passive mode, the control channel is built first, the difference lies in the transfer methods.)

## FTP installation and configuration

### Preparations

Vsftpd is a light, safe and easy-to-use FTP server in Linux, and is the most popular FTP server across all Linux releases.

#### Install vsftpd through yum

```shell
yum install -y vsftpd
```

#### Related configuration files

##### 1. Change directory to vsftpd

```shell
cd /etc/vsftpd
```

There are three configuration files that we are concerned about

- `/etc/vsftpd/vsftpd.conf`: main configuration file, which is the core configuration file.
- `/etc/vsftpd/ftpusers`: blacklist, which prevents users on it from accessing the FTP server.
- `/etc/vsftpd/user_list`: Whitelist, which allows users on it to access the FTP server.

##### 2. Start service (in CentOS 7+)

```shell
systemctl enable vsftpd.service # set automatically start on startup
systemctl start vsftpd.service # start FTP service
netstat -antup | grep ftp # view FTP service port
```

### Basic Configuration of Anonymous FTP

With anonymous FTP, a user can log in to the FTP without entering a user name and password. Anonymous FTP is enabled by default after installing vsftpd, a user can log in to the FTP server anonymously without further configuration.

Anonymous FTP configuration is set in `/etc/vsftpd/vsftpd.conf`.

```shell
# YES by default
anonymous_enable=YES 
```

At this time, all users can log in to the FTP server anonymously. They can view and download directories and files in the root folder, but cannot upload files or create directories.

#### The installation of lftp

We can install `lftp` to test, which is a ftp application in Linux.

```shell
yum -y install lftp
```

When lftp connects to the FTP server from a public IP address, you can only view and download files, but you cannot upload files. (Try yourself)

#### Additional anonymous FTP configuration

For safety reasons, in vsftpd, users are not allowed to perform modifying operations such as uploading files or creating directories through anonymous FTP, but the vsftpd.conf configuration file can be modified to grant additional permissions.

##### Allow uploading files through anonymous FTP.

Modify `/etc/vsftpd/vsftpd.conf`

```shell
write_enable=YES
anon_upload_enable=YES
```

Change permissions of the `/var/ftp/pub` directory, granting write permission to FTP users, and reload the configuration file.

```shell
# add write permission to others
chmod o+w /var/ftp/pub  
# restart service
systemctl restart vsftpd.service  
```

Now anonymous users are able to write or read files in remote host.

### Configuration of Security Group

#### Add Security Group Rules for FTPServer

##### Background

Security groups control access to or from public or internal networks. For security purposes, most security groups use deny policies for inbound traffic. If you use the default security group, or you select a Web Server Linux template or a Web Server Windows template when creating a security group, security group rules are automatically added to some communication ports. 

##### Attributes of Security Rules

Security rules mainly describe different access permissions with the following attributes:

- Policy: authorization policies. The parameter value can be accept or drop.
- Priority: priority levels. The priority levels are sorted by creation time in descending order. The rule priority ranges from 1 to 100. The default value is 1, which is the highest priority. A greater value indicates a lower priority.
- NicType: network type. In security group authorization (namely SourceGroupId is specified while SourceCidrIp is not), you must specify NicType as intranet.
- Description:
    - IpProtocol: IP protocol. Values: tcp, udp, icmp, gre or all. The value "all" indicates all the protocols.
    - PortRange: the range of port numbers related to the IP protocol:
        - When the value of IpProtocol is tcp or udp, the port range is 1-65535. The format must be "starting port number/ending port number". For example, "1/200" indicates that the port range is 1-200. If the input value is "200/1", an error will be reported when the interface is called.
        - When the value of IpProtocol is icmp, gre or all, the port range is -1/-1, indicating no restriction on ports.
    - If security group authorization is adopted, the SourceGroupId (namely the source security group ID) should be specified. In this case, you can choose to set SourceGroupOwnerAccount based on whether it is cross-account authorization. SourceGroupOwnerAccount indicates the account to which the source security group belongs.
    - If CIDR authorization is adopted, SourceCidrIp should be specified. SourceCidrIp is the source IP address segment, which must be in the CIDR format.

#### Add 20/21 Port for FTP

To enable port 21 on the Internet to provide FTP services for external applications, do not impose any restrictions on IP network segments but set it to 0.0.0.0/0 in order to allow all inbound requests. For this purpose, you can refer to the following properties where console parameters are outside of brackets and OpenAPI parameters are within brackets (no difference is made if both parameters are the same).

- NIC Type (NicType): Internet (internet). For VPCs, simply enter intranet to implement Internet access through EIP.
- Action (Policy): allow (accept).
- Rule Direction (NicType): inbound.
- Protocol Type (IpProtocol): TCP (tcp).
- Port Range (PortRange): 20/21.
- Authorized Objects (SourceCidrIp): 0.0.0.0/0.
- Priority (Priority): 1.

![securityGroup](codehome/src/img/tutorial/securityGroup.png)

#### Configuration of PASV Mode for FTP

20 port is used for data transfer, so we need to open PASV mode for client to get data from host passively. To do that, we have to open a limit range of ports to ensure the communication between clients and hosts.

![PASVMode](codehome/src/img/tutorial/PASVMode.png)

Meanwhile, make some changes to `vsftpd.conf`

```shell
# allow local users change directory to those of others
chroot_local_user=YES       
# only users in /etc/vsftpd/chroot_list are allowed to change directory to root directory
chroot_list_enable=YES      
# white user list
chroot_list_file=/etc/vsftpd/chroot_list    

# root directory for local users is home directory
# local_root=${HOME_DIR}    

# PASV Mode
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=40080
pasv_promiscuous=YES
```

### Configure Local User Login

Local user login refers to logging in to the FTP server with the Linux user name and password. Only anonymous FTP login is supported after vsftp is installed, if a user tries to log in to the server with the Linux user name, vsftp will deny access.

Now let's configure local user login.

Create user ftpUser

```shell
# create user ftpUser
useradd ftpUser 
# set password of ftpUser
passwd ftpUser 
```

##### Modify vsftpd.conf

```shell
# shutdown permission of anonymous users
anonymous enable=NO 
# open ftp channel to local users
local_enable=YES 
```

Login with user ftpUser,

![ftpUser](codehome/src/img/tutorial/ftpUser.png)

#### Additional vsftpd.conf Parameters

```shell
cat /etc/vsftpd/vsftpd.conf
```

##### User Login Control

| Parameter | Description| 
| :---: | :---: | 
anonymous_enable=YES | Anonymous users are accepted 
no_anon_password=YES | Password is not requested when anonymous users log in
anon_root=(none) | Anonymous user root
local_enable=YES | Local users are accepted
local_root=(none) | Local root user

##### User Permission Control

| Parameter | Description |
| :---: | :---: |
write_enable=YES | upload is enabled (global control)
local_umask=022 | umask for local user to upload files
file_open_mode=0666	| Use umask for uploaded file permissions
anon_upload_enable=YES | upload is enabled for anonymous users
anon_mkdir_write_enable=YES | creating directories is enabled for anonymous users
anon_other_write_enable=YES | modifying and deleting are enabled for anonymous users
chown_username=lightwiter | owner user name of uploaded files by anonymous users

<EndMarkdown>
