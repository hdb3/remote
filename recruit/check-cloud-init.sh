#!/bin/bash

    defaultkey="/home/nic/.ssh/openstack_rsa"
    host="$1"


attempt_login() {

# assumes that $host and $user is already set
# if $key is set then try key authentication
# otherwise  if $passwd is set try password authentication

    if [[ -z "$user" ]]
      then echo "user not set!"
      exit
    fi

    if [[ -z "$host" ]]
      then echo "user not set!"
      exit
    fi

    SSHOPTIONS="-q -tt"
    SSHOPTIONS="$SSHOPTIONS -o UserKnownHostsFile=/dev/null"
    SSHOPTIONS="$SSHOPTIONS -o StrictHostKeyChecking=no"
    SSHOPTIONS="$SSHOPTIONS -F /dev/null"

    CMD="$(which ssh)"
    if [[ -n "$key" ]]
      then
        XOPTS="-i${key} -o PasswordAuthentication=no"
      elif [[ -n "$passwd" ]]
      then
        XOPTS="-o PasswordAuthentication=yes"
        which sshpass > /dev/null || ( echo "please install sshpass" ; exit )
        CMD="$(which sshpass) -p $passwd $CMD"
      else
        echo "attempt_login called with neither\$key nor \$passwd set"
        return 1
    fi

    # only get here if we have a key or a password

    XCMD="${CMD} ${SSHOPTIONS} ${XOPTS} -l ${user} ${host}"
    ruser=$(${XCMD} sudo whoami)

    if [[ "$ruser" =~ "root" ]]
      then
        # echo "attempt_login() succeeded with user ${user}"
        return 0
      else
        # echo "attempt_login() failed with user ${user}"
        return 1
    fi
}

which fping > /dev/null && fping $host

if [[ -z $2 ]]
  then
    echo "using key from $defaultkey key"
    cloudkey="$defaultkey"
  else
    cloudkey="$2"
fi

if [[ -f "${cloudkey}" ]]
  then
    echo "trying key based login"
    key="${cloudkey}"
    for user in cirros centos ubuntu
    do
      if attempt_login
        then
          # echo "succeeded with user ${user}"
          xuser="${user}"
          break
        else
          :
          # echo "failed with user ${user}"
      fi
    done
  else
    echo "the cloud key file (${cloudkey}) was not found"
fi
if [[ -z "$xuser" ]]
  then
    echo "trying password based login"
    unset key
    passwd="root"
    user="root"
    if attempt_login
      then
        # echo "succeeded with user ${user}"
        xuser="${user}"
      else
        :
        # echo "failed with user ${user}"
    fi
fi

if [[ -z $xuser ]]
  then
    echo "all logins failed"
  else
    echo "login succeeded with user '$xuser'"
    echo "the required ssh command is: ${XCMD}"
fi
