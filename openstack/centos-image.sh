#!/bin/bash
curl http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2.xz | xzcat - | glance image-create --name centos7 --disk-format qcow2 --container-format bare --progress
