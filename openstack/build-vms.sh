#!/bin/bash
BASEIMAGE="centos72-osbase"
set -e
VMS="os-controller os-compute1 os-compute2"
declare -A SPEC
SPEC["os-compute1"]="52:54:00:27:a0:7f 4G 3 100G"
SPEC["os-compute2"]="52:54:00:b0:c0:9a 4G 3 100G"
SPEC["os-controller"]="52:54:00:6c:7b:24 2G 2 100G"

function add_disk () {
  virsh vol-create-as default ${1}-${2} ${3} --format qcow2
  virsh attach-disk ${1} --source /var/lib/libvirt/images/${1}-${2} ${2} --driver qemu --subdriver qcow2 --config
}

function clone_ () {
  if [[ $# -ne 5 ]] ; then
    echo "problem with name or spec ($#) [$@]"
    exit 1
  fi
  virt-clone -o $BASEIMAGE -n $1 --mac $2 --auto-clone
  virsh setmaxmem $1 $3 --config
  virsh setmem $1 $3 --config
  virsh setvcpus $1 $4 --maximum --config
  add_disk $1 vdb $5
}

function clone () {
  clone_ $1 ${SPEC[$1]}
}

function destroy () {
    virsh destroy ${1} || :
    virsh undefine ${1} --nvram --remove-all-storage --snapshots-metadata || :
}

function ccheck () {
  echo  -n "waiting for ping ($1)"
  until fping $1 &> /dev/null
    do
      echo -n "."
    done
  echo "done ($1)"
  echo  -n "waiting for ssh ($1)"
  set +e
  su  -p -c "ssh-keygen -f ~/.ssh/known_hosts -R $vm" $SUDO_USER > /dev/null
  ssh-keygen -f /root/.ssh/known_hosts -R $vm > /dev/null
  set -e
  sshpass -p root ssh -q -o ConnectionAttempts=100 -o ConnectTimeout=1 root@${1} pwd > /dev/null
  echo "done"
}

if [[ $EUID -ne 0 ]]; then
   echo "you probably want to run this script as root" 
   exit 1
fi

for vm in $VMS
  do
    destroy $vm
    clone $vm
    virsh start $vm
  done

for vm in $VMS
  do
    ccheck $vm
  done

echo "all VMs built OK and running....."
