#!/bin/bash -e

if [ -s recruit/adminkey.gpg ] ; then
  which gpg || ( echo "please install gpg" ; exit )
  grep '^IdentityFile.*id_rsa' ~/.ssh/config >> /dev/null || \
    ( echo "adding id_rsa to .ssh/config" ; echo "IdentityFile ~/.ssh/id_rsa" >> ~/.ssh/config )
  grep '^IdentityFile.*adminkey' ~/.ssh/config >> /dev/null || \
    ( echo "adding adminkey to .ssh/config" ; echo "IdentityFile ~/.ssh/adminkey" >> ~/.ssh/config )
  gpg -q recruit/adminkey.gpg
  mv -vn recruit/adminkey ~/.ssh/ || rm recruit/adminkey
else
  echo "recruit/adminkey is not accessible, so I can't install it for you"
fi
