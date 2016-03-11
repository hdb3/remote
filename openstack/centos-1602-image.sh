#!/bin/bash
URL=http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud-1602.qcow2.xz
NAME=centos1602
curl $URL | xzcat - | glance image-create --name $NAME --disk-format qcow2 --container-format bare --progress
