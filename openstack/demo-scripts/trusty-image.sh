#!/bin/bash
curl https://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img | glance image-create --name  trusty --disk-format qcow2 --container-format bare --progress
