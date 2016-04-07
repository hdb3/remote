#!/bin/bash -ev
USAGE="Usage: $0 host1 host2 ... hostN"
# USAGE="Usage: dir host1 host2 ... hostN"
KEYFILENAME="cloudkey.pem"

if [ "$#" -lt "1" ]; then
	echo "$USAGE"
	exit 1
fi

if [ -f recruit/user ]; then
  user=$(<recruit/user)
else
  user=root
fi

if [ -f recruit/passwd ]; then
  passwd=$(<recruit/passwd)
else
  passwd=root
fi

if [ -f recruit/$KEYFILENAME ]; then
  key="$(pwd)/recruit/$KEYFILENAME"
else
  unset key
  echo "cannot find recruit/$KEYFILENAME - will not use cloudinit for initial login"
fi

for host in "$@"
do
    # echo "recruiting $host"
    echo "recruiting " "$host" "$user" "$passwd" "$key"
    recruit-admin/recruit-admin.sh "$host" "$user" "$passwd" "$key"
done
