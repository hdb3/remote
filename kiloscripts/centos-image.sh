#!/bin/bash
wget http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2.xz
unxz CentOS-7-x86_64-GenericCloud.qcow2
glance image-create --name "centos7" --file CentOS-7-x86_64-GenericCloud.qcow2 --disk-format qcow2 --container-format bare --is-public True --progress
