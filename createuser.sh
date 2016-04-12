#!/bin/bash -e

if [ "$#" -lt "1" ]; then echo "please give at least a remote host name"; exit ; fi
if [ "$#" -lt "2" ]; then user="centos" ; else user="$2" ; fi
echo "useradd -d /home/${user} -m ${user} && echo ${user}:${user} | chpasswd && echo '${user} ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers" | ssh -tt root@$1
