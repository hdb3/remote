#!/bin/bash -e

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
  user="$user@"
fi

for node in "$@"
do
    echo "$node (${user}${node})"
    ssh-keygen -q -f "/home/nic/.ssh/known_hosts" -R `dig +short $node`
    ssh-keygen -q -f "/home/nic/.ssh/known_hosts" -R $node
    scp $wd/* ${user}${node}:
    ssh -t ${user}${node} sudo bash -ve do_it
done
