#!/bin/bash
curl https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img | glance image-create --name "ubuntu-16.04" --disk-format qcow2 --container-format bare --progress --visibility public
