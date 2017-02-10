#!/bin/bash -ev
# this script assumes that an image 'cirros' exists
# and that a network 'default' exists
source creds
openstack keypair create --public-key openstack_rsa.pub openstack_rsa
for host in testvm1 testvm2
  do
  # the 'exit' in the awk avoids matching on more than one line...
    openstack server create --wait \
        --key-name openstack_rsa \
        --flavor `openstack flavor list|awk '/tiny/ {print $2;exit}'` \
        --image `openstack image list|awk '/cirros/ {print $2;exit}'` \
        --nic net-id=`neutron net-list| awk '/default/ {print $2;exit}'` \
        $host
  done
exit

openstack keypair delete openstack_rsa
openstack server delete testvm1 testvm2
neutron router-interface-delete r1 testnet
neutron router-delete r1
neutron subnet-delete testnet
neutron net-delete testnet
