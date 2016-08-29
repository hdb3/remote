#!/bin/bash
set -e
if [[ $EUID -ne 0 ]]; then
   echo "you probably want to run this script as root" 
exit 1
fi
for vm in os-controller os-compute1
  do
    virsh destroy $vm || :
    virsh undefine $vm --nvram --remove-all-storage --snapshots-metadata || :
  done

virt-clone -o centos72-ks2 -n os-controller --mac 52:54:00:6c:7b:24 --auto-clone
virsh attach-interface --domain os-controller --mac 52:54:00:2d:d7:95 --type bridge --source br1 --config --persistent
virsh setmaxmem os-controller 4G --config
virsh setmem os-controller 4G --config

virt-clone -o centos72-ks2 -n os-compute1 --mac 52:54:00:27:a0:7f --auto-clone
virsh attach-interface --domain os-compute1 --mac 52:54:00:9e:43:3c --type bridge --source br1 --config --persistent
virsh setmaxmem os-compute1 8G --config
virsh setmem os-compute1 8G --config
virsh setvcpus os-compute1 3 --maximum --config
virsh vol-create-as default os-compute1-vdb 256G --format qcow2
virsh attach-disk os-compute1 --source /var/lib/libvirt/images/os-compute1-vdb vdb --driver qemu --subdriver qcow2 --config

for vm in os-controller os-compute1
  do
    virsh start $vm
    ssh-keygen -f ~/.ssh/known_hosts -R $vm
    ssh-keygen -f /root/.ssh/known_hosts -R $vm
  done

echo  -n "waiting for ping"
until fping os-controller os-compute1 &> /dev/null
  do
    #read -p "." -t 1 || :
    echo -n "."
  done
echo "done"

echo -n "checking ssh access...."
sshpass -p root ssh -q -o ConnectionAttempts=100 -o ConnectTimeout=1 root@os-controller pwd > /dev/null
echo "done"

echo "all VMs built OK and running....."
