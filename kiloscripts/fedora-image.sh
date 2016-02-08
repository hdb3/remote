#!/bin/bash
wget https://download.fedoraproject.org/pub/fedora/linux/releases/23/Cloud/x86_64/Images/Fedora-Cloud-Base-23-20151030.x86_64.qcow2
glance image-create --name "fedora" --file Fedora-Cloud-Base-23-20151030.x86_64.qcow2 --disk-format qcow2 --container-format bare --progress
