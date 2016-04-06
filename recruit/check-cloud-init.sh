#!/bin/bash

attempt_login() {

# assumes that $host and $user is already set
# if $key is set then try key authentication
# otherwise  if $passwd is set try password authentication

    if [[ -z "$user" ]]
      then echo "user not set!"
      exit
    fi

    if [[ -z "$host" ]]
      then echo "host not set!"
      exit
    fi

    SSHOPTIONS="-F recruit/ssh_config"
    #SSHOPTIONS="-q -tt"
    #SSHOPTIONS="$SSHOPTIONS -o UserKnownHostsFile=/dev/null"
    #SSHOPTIONS="$SSHOPTIONS -o StrictHostKeyChecking=no"

    CMD="$(which ssh)"
    if [[ -n "$key" ]]
      then
        XOPTS="-i${key} -o PasswordAuthentication=no"
        PRECMD=""
      elif [[ -n "$passwd" ]]
      then
        XOPTS="-o PasswordAuthentication=yes"
        which sshpass > /dev/null || ( echo "please install sshpass" ; exit )
        PRECMD="$(which sshpass) -p $passwd"
      else
        echo "attempt_login called with neither\$key nor \$passwd set"
        return 1
    fi

    # only get here if we have a key or a password

    XCMD="$PRECMD ${CMD} ${SSHOPTIONS} ${XOPTS} -q -tt -l ${user} ${host}"
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

attempt_all_logins() {

  if [[ -f "${key}" ]]
    then
      echo "trying key based login"
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
      echo "the key file (${key}) was not found"
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
}

attempt_ssh_copy_id() {
   if ${PRECMD} ssh-copy-id ${SSHOPTIONS} ${SSHTARGET}
    then
      echo "ssh-copy-id - sucess!"
      rval=0
     else
      echo "ssh-copy-id : something went wrong!"
      rval=1
   fi
   return $rval
}

attempt_scp() {
   tmpfile=$(mktemp /tmp/XXXXXX)
   dd if=/dev/urandom of=$tmpfile count=1
   echo "${PRECMD} scp -q ${SSHOPTIONS} $tmpfile ${SSHTARGET}:$tmpfile" 
   ${PRECMD} scp -q ${SSHOPTIONS} "$tmpfile" "${SSHTARGET}:$tmpfile" 
   echo "${PRECMD} scp -q ${SSHOPTIONS} ${SSHTARGET}:$tmpfile ${tmpfile}.copy" 
   ${PRECMD} scp -q ${SSHOPTIONS} "${SSHTARGET}:$tmpfile" "${tmpfile}.copy" 
   if diff -q "$tmpfile" "$tmpfile.copy"
    then
      echo "scp test - sucess!"
      rval=0
     else
      echo "scp test: something went wrong!"
      rval=1
   fi
   rm "$tmpfile"
   rm -f "${tmpfile}.copy"
   return $rval
}
#############################################################

# main

#############################################################

defaultkey="/home/nic/.ssh/openstack_rsa"
host="$1"

which fping > /dev/null && fping $host

if [[ -z $2 ]]
  then
    echo "using key from $defaultkey key"
    key="$defaultkey"
  else
    key="$2"
fi

if attempt_all_logins
  then
    SSHOPTIONS="${SSHOPTIONS} ${XOPTS}"
    SSHTARGET="${user}@${host}"
    echo "login succeeded with user '$xuser'"
    echo "the required pre ssh command is: ${PRECMD}"
    echo "the required ssh options are: ${SSHOPTIONS}"
    echo "the required ssh target is: ${SSHTARGET}"
    attempt_scp
    attempt_ssh_copy_id
  else
    echo "all logins failed"
fi
