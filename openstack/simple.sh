#!/bin/bash -ev
source creds
openstack keypair create --public-key openstack_rsa.pub openstack_rsa
neutron net-create testnet
neutron subnet-create --name testnet testnet 172.16.42.0/24
neutron router-create r1 # a router is needed in order to get metadata service over network
neutron router-interface-add r1 testnet
for host in testvm1 testvm2
  do
  # the 'exit' in the awk avoids matching on more than one line...
    openstack server create --wait \
        --key-name openstack_rsa \
        --flavor `openstack flavor list|awk '/tiny/ {print $2;exit}'` \
        --image `openstack image list|awk '/cirros/ {print $2;exit}'` \
        --nic net-id=`neutron net-list| awk '/testnet/ {print $2;exit}'` \
        $host
  done

exit

openstack keypair delete openstack_rsa
openstack server delete testvm1
neutron router-interface-delete r1 testnet
neutron router-delete r1
neutron subnet-delete testnet
neutron net-delete testnet
