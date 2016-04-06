export RESERVED1="$(findmnt --noheadings --list --fstab --evaluate -o SOURCE|grep -v '^/dev/mapper')"
export RESERVED2="$(pvs --noheadings -o pv_name)"
export DISKS="$(lsblk  -l -p -n |grep disk | awk '{print $1}')"
for d in $DISKS 
 do
  if [[ $RESERVED1 =~ $d || $RESERVED2 =~ $d ]] 
  then
    : # echo "protecting $d" 
    pd="$pd $d" 
  else
    : # echo "formatting $d" 
    dd="$dd $d" 
  fi 
 done
 echo "will overwrite $dd"
 echo "will protect $pd"
 echo -n "continue?"
 read n
 which sgdisk
 for dev in $dd
   do
      echo "formatting $dev"
      sgdisk -Z $dev
   done
 partprobe

