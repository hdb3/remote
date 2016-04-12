#!/bin/bash -e

if [ -s recruit/adminkey ] ; then
  grep '^IdentityFile.*id_rsa' ~/.ssh/config >> /dev/null || \
    ( echo "adding id_rsa to .ssh/config" ; echo "IdentityFile ~/.ssh/id_rsa" >> ~/.ssh/config )
  grep '^IdentityFile.*adminkey' ~/.ssh/config >> /dev/null || \
    ( echo "adding adminkey to .ssh/config" ; echo "IdentityFile ~/.ssh/adminkey" >> ~/.ssh/config )
  cp -vn recruit/adminkey ~/.ssh/
else
  echo "recruit/adminkey is not accessible, so I can't install it for you"
fi
