useradd -d /home/centos -m centos && echo centos:centos | chpasswd && echo 'centos ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
