#!/bin/bash
BASEIMAGE="centos72-osbase"
set -e
COMPUTE_VMS="os-compute1 os-compute2"
declare -A MAC
MAC["os-compute1"]=52:54:00:27:a0:7f
MAC["os-compute2"]=52:54:00:b0:c0:9a
for vm in $COMPUTE_VMS ; do echo $vm ; echo "${MAC[$vm]}" ; done

function add_disk () {
  virsh vol-create-as default ${1}-${2} ${3} --format qcow2
  virsh attach-disk ${1} --source /var/lib/libvirt/images/${1}-${2} ${2} --driver qemu --subdriver qcow2 --config
}

if [[ $EUID -ne 0 ]]; then
   echo "you probably want to run this script as root" 
exit 1
fi
for vm in os-controller $COMPUTE_VMS
  do
    virsh destroy $vm || :
    virsh undefine $vm --nvram --remove-all-storage --snapshots-metadata || :
  done

virt-clone -o $BASEIMAGE -n os-controller --mac 52:54:00:6c:7b:24 --auto-clone
#virsh vol-create-as default os-controller-vdb 256G --format qcow2
#virsh attach-disk os-controller --source /var/lib/libvirt/images/os-controller-vdb vdb --driver qemu --subdriver qcow2 --config
add_disk os-controller vdb 100G
#virsh attach-interface --domain os-controller --mac 52:54:00:2d:d7:95 --type bridge --source br1 --config --persistent
#virsh attach-interface --domain os-controller --mac 52:54:00:64:04:95 --type bridge --source br2 --config --persistent
virsh setmaxmem os-controller 2G --config
virsh setmem os-controller 2G --config

for vm in $COMPUTE_VMS
  do
    virt-clone -o $BASEIMAGE -n $vm --mac ${MAC[$vm]} --auto-clone
    virsh setmaxmem $vm 4G --config
    virsh setmem $vm 4G --config
    virsh setvcpus $vm 3 --maximum --config
    #virsh vol-create-as default $vm-vdb 256G --format qcow2
    #virsh attach-disk $vm --source /var/lib/libvirt/images/$vm-vdb vdb --driver qemu --subdriver qcow2 --config
    add_disk $vm vdb 100G
  done

for vm in os-controller $COMPUTE_VMS
  do
    virsh start $vm
    set +e
    su  -p -c "ssh-keygen -f ~/.ssh/known_hosts -R $vm" $SUDO_USER
    ssh-keygen -f /root/.ssh/known_hosts -R $vm
    set -e
  done

echo  -n "waiting for ping"
until fping os-controller os-compute1 &> /dev/null
  do
    echo -n "."
  done
echo "done"

echo -n "checking ssh access...."
sshpass -p root ssh -q -o ConnectionAttempts=100 -o ConnectTimeout=1 root@os-controller pwd > /dev/null
echo "done"

echo "all VMs built OK and running....."
