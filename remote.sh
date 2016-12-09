#!/bin/bash -ex

#check early for non-standard utilities...
which fping > /dev/null

USAGE="Usage: $0 dir host1 host2 ... hostN"

if [ "$#" -lt "2" ]; then
	echo "$USAGE"
	exit 1
fi

wd=$1
shift
if [ ! -d $wd ]; then
  echo "$wd is not a directory"
fi

if [ ! -f $wd/do_it ]; then
  echo "$wd/do_it does not exist"
fi

if [ -f $wd/user ]; then
  user=$(<$wd/user)
fi

if [ -f $wd/password ]; then
  which sshpass > /dev/null
  password=$(<$wd/password)
fi

for node in "$@"
do
    target="${user}@${node}"
    echo "$node ($target)"
    echo  -n "waiting for ping"
    until fping $node &> /dev/null
      do
        echo -n "."
      done
    echo "done"
    echo -n "checking ssh access...."
    if [ -n "$password" ] ; then
      sshpass -p $password ssh-copy-id -o ControlPath=none -o ConnectionAttempts=100 -o ConnectTimeout=1 $target
    else
      ssh -q -o ConnectionAttempts=100 -o ConnectTimeout=1 $target pwd > /dev/null
    fi
    echo "done"
    scp $wd/* $target:
    if [ -d $wd/.ssh ]; then
        scp -r $wd/.ssh $target:
    fi
    ssh -t ${target} sudo bash -xe do_it
done
