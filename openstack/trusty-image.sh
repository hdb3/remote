#!/bin/bash
wget https://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img
glance image-create --name "ubuntu-15.10" --file trusty-server-cloudimg-amd64-disk1.img --disk-format qcow2 --container-format bare --progress
