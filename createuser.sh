#!/bin/bash -ex

# this utility requires a root capable user rather than a sudo user
# because in many cases, e.g. RHEL/Centos, sudo is not available via remote ssh sessions until the suoders configuration is updated

if [ "$#" -lt "1" ]; then echo "usage: $0 hostname root-password new-user remote-root-user" ; exit ; fi
if [ "$#" -lt "2" ]; then remote_root_passwd="root" ; else remote_root_passwd="$2" ; fi
if [ "$#" -lt "3" ]; then user="centos" ; else user="$3" ; fi
if [ "$#" -lt "4" ]; then remote_root_user="root" ; else remote_root_user="$4" ; fi
echo "setting up user:$user on host:$1 using remote root credentials $remote_root_user:$remote_root_passwd"
password_hash=`openssl passwd $user`
sshpass -p $remote_root_passwd ssh ${remote_root_user}@${1} useradd -p ${password_hash} -m $user
sshpass -p $remote_root_passwd ssh ${remote_root_user}@${1} "echo '$user ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"
sshpass -p $remote_root_passwd ssh ${remote_root_user}@${1} "sed -i -e '/requiretty/ s/^Defaults/#Defaults/' /etc/sudoers"
