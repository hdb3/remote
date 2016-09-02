#!/bin/bash
BASEIMAGE="centos72-osbase"
MEM=8G
DISK2=256G
NAME=os-allinone
MAC=52:54:00:7b:a4:c8
set -e
if [[ $EUID -ne 0 ]]; then
   echo "you probably want to run this script as root" 
exit 1
fi
virsh destroy $NAME || :
virsh undefine $NAME --nvram --remove-all-storage --snapshots-metadata || :

virt-clone -o $BASEIMAGE -n $NAME --mac $MAC  --auto-clone
virsh setmaxmem $NAME $MEM --config
virsh setmem $NAME $MEM --config
virsh vol-create-as default ${NAME}-vdb $DISK2 --format qcow2
virsh attach-disk $NAME --source /var/lib/libvirt/images/${NAME}-vdb vdb --driver qemu --subdriver qcow2 --config
virsh start $NAME
until fping $NAME &> /dev/null
    do
      echo -n "."
    done


echo -n "checking ssh access...."
sshpass -p root ssh -q -o ConnectionAttempts=100 -o ConnectTimeout=1 root@$NAME pwd > /dev/null
echo "done"

echo "built OK and running....."
