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

function sshclean {
    echo "sshclean $1"
    # ssh-keygen -q -f "~/.ssh/known_hosts" -R `dig +short $1`
    # ssh-keygen -q -f "~/.ssh/known_hosts" -R $1
}

for node in "$@"
do
    echo "$node (${user}${node})"

    # if [ -f $wd/password ]; then
      # which sshpass || ( echo "please install sshpass" ; exit )
      # sshpass -p `cat $wd/password` ssh-copy-id ${user}${node}
    # fi

    # sshclean $node || echo "sshclean?"
    echo "scp $wd/* ${user}${node}:"
    scp $wd/* ${user}${node}:
    ssh -t ${user}${node} sudo bash -ve do_it
done
