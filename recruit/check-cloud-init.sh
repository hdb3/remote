#!/bin/bash

defaultkey="/home/nic/.ssh/openstack_rsa"
host="$1"

SSH=$(which ssh)

which fping && fping $host

if [[ -z $2 ]]
  then
    echo "using key from $defaultkey key"
    cloudkey="$defaultkey"
  else
    cloudkey="$2"
fi

if [[ -f "${cloudkey}" ]]
  then
    SSHOPTIONS="-o UserKnownHostsFile=/dev/null"
    SSHOPTIONS="$SSHOPTIONS -o PasswordAuthentication=no"
    SSHOPTIONS="$SSHOPTIONS -o StrictHostKeyChecking=no"
    SSHOPTIONS="$SSHOPTIONS -F /dev/null"
    SSHOPTIONS="$SSHOPTIONS -i${cloudkey}"
    SSHOPTIONS="$SSHOPTIONS -q -tt"
    for user in cirros centos ubuntu
    do
      CMD="$SSH ${SSHOPTIONS} -l ${user} ${host} sudo whoami"
      # echo "trying $CMD"
      ruser=$(${CMD})
      if [[ "$ruser" =~ "root" ]]
        then
          echo "succeeded with user ${user}"
          xuser="${user}"
        else
          echo "failed with user ${user}"
      fi
    done
  else
    echo "the cloud key file (${cloudkey}) was not found"
fi

if [[ -z $xuser ]]
  then
    echo "all logins failed"
  else
    echo "login succeeded with '$xuser'"
fi
