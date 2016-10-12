#!/bin/bash -exv

if [ "$#" -lt "1" ]; then echo "please give at least a remote host name; optionally also the new username and the remote sudo user to work as"; exit ; fi
if [ "$#" -lt "2" ]; then user="centos" ; else user="$2" ; fi
if [ "$#" -lt "3" ]; then remote_user="root" ; else remote_user="$3" ; fi
echo "sudo useradd -d /home/${user} -m ${user}" | ssh -t $remote_user@$1
echo "echo ${user}:${user} | sudo chpasswd " | ssh -t $remote_user@$1
echo "echo \"${user} ALL=(ALL) NOPASSWD: ALL\" sudo tee -a /etc/sudoers" | ssh -t $remote_user@$1
#echo "useradd -d /home/${user} -m ${user} && echo ${user}:${user} | chpasswd && echo '${user} ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers" | ssh -tt root@$1
