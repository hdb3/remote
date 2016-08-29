#!/bin/bash
set -e
if [[ $EUID -ne 0 ]]; then
   echo "you probably want to run this script as root" 
exit 1
fi
for vm in vm1 vm2 vm3 vm4 ceph-client ceph-deploy
  do
    virsh destroy $vm || :
    virsh undefine $vm --nvram --remove-all-storage --snapshots-metadata || :
    #virsh undefine $vm --nvram --remove-all-storage --delete-snapshots --snapshots-metadata || :
  done

virt-clone -o centos72-ks2 -n vm1 --mac 52:54:00:44:b4:f9 --auto-clone
#virt-clone -o centos72-ks -n vm1 --auto-clone
for d in vdb vdc vdd
  do
    virsh vol-create-as default $d 8G --format qcow2
    virsh attach-disk vm1 --source /var/lib/libvirt/images/$d $d --driver qemu --subdriver qcow2 --config
  done 
#
#for vm in vm2 vm3 vm4
#  do
#    virt-clone -o vm1 -n $vm --auto-clone
#  done
virt-clone -o vm1 -n vm2 --mac 52:54:00:62:30:16 --auto-clone
virt-clone -o vm1 -n vm3 --mac 52:54:00:ca:0d:ba --auto-clone
virt-clone -o vm1 -n vm4 --mac 52:54:00:d0:c4:ae --auto-clone
virt-clone -o centos72-ks2 -n ceph-client --mac 52:54:00:99:dd:ca --auto-clone
virt-clone -o centos72-ks2 -n ceph-deploy --mac 52:54:00:08:84:c4 --auto-clone

for vm in vm1 vm2 vm3 vm4 ceph-client ceph-deploy
  do
    virsh start $vm
    ssh-keygen -f ~/.ssh/known_hosts -R $vm
    ssh-keygen -f /root/.ssh/known_hosts -R $vm
  done

echo  -n "waiting for ping"
until fping vm1 vm2 vm3 vm4 ceph-client ceph-deploy &> /dev/null
  do
    read -p "." -t 1 || :
  done
echo "done"
fping vm1 vm2 vm3 vm4 ceph-client ceph-deploy

sshpass -p root ssh -o ConnectionAttempts=100 -o ConnectTimeout=1 root@ceph-deploy pwd

echo "all VMs built OK and running....."
