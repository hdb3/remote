#!/bin/bash

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

recho() { echo "${red}${1}${reset}"; }
gecho() { echo "${green}${1}${reset}"; }
yecho() { echo "${yellow}${1}${reset}"; }

attempt_login() {

# assumes that $host and $user is already set
# if $key is set then try key authentication
# otherwise  if $passwd is set try password authentication

    if [[ -z "$user" ]]
      then recho "user not set!"
      exit
    fi

    if [[ -z "$host" ]]
      then recho "host not set!"
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
    # the reason it is used here is that sudo typically requires a tty, so the initial probe which has to check for an sudo user must use it.
    # note: -tt could also be done via config option RequireTTY
    #SSHOPTIONS="-tt"

    CMD="$(which ssh)"
    if [[ -n "$key" ]]
      then
        XOPTS="-o IdentityFile=${key} -o PasswordAuthentication=no"
        PRECMD=""
      elif [[ -n "$passwd" ]]
      then
        XOPTS="-o PasswordAuthentication=yes -o PubkeyAuthentication=no"
        PRECMD="$(which sshpass) -p $passwd"
      else
        recho "attempt_login called with neither\$key nor \$passwd set"
        return 1
    fi

    # only get here if we have a key or a password

    XCMD="$PRECMD ${CMD} ${SSHOPTIONS} ${XOPTS} -tt -l ${user} ${host}"
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
      yecho "trying key based login"
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
      recho "the key file (${key}) was not found"
  fi
  if [[ -z "$xuser" ]]
    then
      yecho "trying password based login"
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
      gecho "ssh-copy-id - sucess!"
      rval=0
     else
      recho "ssh-copy-id : something went wrong!"
      rval=1
   fi
   return $rval
}

attempt_scp() {
   tmpfile=$(mktemp /tmp/XXXXXX)
   dd if=/dev/urandom of=$tmpfile count=1 2>/dev/null
   # echo "${PRECMD} scp ${SSHOPTIONS} $tmpfile ${SSHTARGET}:$tmpfile" 
   ${PRECMD} scp -q ${SSHOPTIONS} "$tmpfile" "${SSHTARGET}:$tmpfile" 
   # echo "${PRECMD} scp ${SSHOPTIONS} ${SSHTARGET}:$tmpfile ${tmpfile}.copy" 
   ${PRECMD} scp -q ${SSHOPTIONS} "${SSHTARGET}:$tmpfile" "${tmpfile}.copy" 
   if diff -q "$tmpfile" "$tmpfile.copy"
    then
      gecho "scp test - sucess!"
      rval=0
     else
      recho "scp test: something went wrong!"
      rval=1
   fi
   rm "$tmpfile"
   rm -f "${tmpfile}.copy"
   return $rval
}
#############################################################

# main

#############################################################


# will be called as:
#                   recruit-admin/recruit-admin.sh "$host" "$user" "$passwd" "$key"

host="$1"
user="$2"
passwd="$3"
key="$4"

which sshpass > /dev/null || ( echo "please install sshpass" ; exit )
which fping > /dev/null || ( echo "please install fping" ; exit )
fping $host > /dev/null

if attempt_all_logins
  then
    SSHOPTIONS="${SSHOPTIONS} ${XOPTS}"
    SSHTARGET="${user}@${host}"
    ssh_sudo() { eval "${PRECMD} ssh -tt ${SSHOPTIONS} ${SSHTARGET} \"$1\"" ; }
    # gecho "login succeeded with user '$xuser'"
    # gecho "the required pre ssh command is: ${PRECMD}"
    # gecho "the required ssh options are: ${SSHOPTIONS}"
    # gecho "the required ssh target is: ${SSHTARGET}"
    attempt_scp
    attempt_ssh_copy_id
    ssh_sudo "useradd -d /home/admin -m admin"
    ssh_sudo "echo 'admin ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"
    ssh_sudo "mkdir /home/admin/.ssh"
    ssh_sudo "echo $(<${key}) >> /home/admin/.ssh/authorized_keys"
    ssh_sudo "chown admin:admin -R /home/admin/.ssh"
  else
    recho "all logins failed"
fi
