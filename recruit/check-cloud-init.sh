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

    SSHOPTIONS=""
    SSHOPTIONS="$SSHOPTIONS -o UserKnownHostsFile=/dev/null"
    SSHOPTIONS="$SSHOPTIONS -o StrictHostKeyChecking=no"
    SSHOPTIONS="$SSHOPTIONS -o ControlPath=none"
    SSHOPTIONS="$SSHOPTIONS -o ConnectionAttempts=20"
    SSHOPTIONS="$SSHOPTIONS -o ConnectTimeout=1"
    SSHOPTIONS="$SSHOPTIONS -o LogLevel=QUIET" # or FATAL, ERROR, INFO, VERBOSE, DEBUG

    # this option is fine except that ssh-copy-id doesn't support it (though it uses ssh so it could....)
    # 
    #SSHOPTIONS="-F recruit/ssh_config"

    # similarly, -tt is not an option to scp.... (as it wouldn't be needed). And ssh-copy-id doesn't need it
    # the reson it is used here is that sudo typically requires a tty, so the initial probe which has to check for an sudo user must use it.
    #SSHOPTIONS="-q -tt"

    CMD="$(which ssh)"
    if [[ -n "$key" ]]
      then
        XOPTS="-o IdentityFile=${key} -o PasswordAuthentication=no"
        PRECMD=""
      elif [[ -n "$passwd" ]]
      then
        XOPTS="-o PasswordAuthentication=yes -o PubkeyAuthentication=no"
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
