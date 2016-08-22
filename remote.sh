#!/bin/bash -ev

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
    scp -r $wd/* ${user}${node}:
    scp $wd/do_it.local ${user}${node}:do_it || echo "no local do_it file"
    if [ -d $wd/.ssh ]; then
        scp -r $wd/.ssh ${user}${node}:
    fi
    ssh -t ${user}${node} sudo bash -ve do_it
done


