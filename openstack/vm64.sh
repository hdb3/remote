#!/bin/bash -ev
source creds
source config
openstack keypair create --public-key openstack_rsa.pub openstack_rsa || :
IMAGE=`openstack image list|awk '/cirros/ {print $2;exit}'`
FLAVOR=`openstack flavor list|awk '/tiny/ {print $2;exit}'`
NETID=`neutron net-show -f value -c id $INTNAME`
for host in testvm1 testvm2
  do
  # the 'exit' in the awk avoids matching on more than one line...
    openstack server create --wait \
        --key-name openstack_rsa --flavor $FLAVOR --image $IMAGE --nic net-id=$NETID $host
  done

