#!/bin/bash
wget https://cloud-images.ubuntu.com/wily/current/wily-server-cloudimg-amd64-disk1.img
glance image-create --name "ubuntu-15.10" --file wily-server-cloudimg-amd64-disk1.img --disk-format qcow2 --container-format bare --progress
