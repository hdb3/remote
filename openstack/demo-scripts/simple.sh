#!/bin/bash -ev
localdir=`dirname $0`
source creds
openstack keypair create --public-key $localdir/openstack_rsa.pub openstack_rsa
neutron net-create testnet
export NETID=`neutron net-list| awk '/ testnet / {print $2}'`
neutron subnet-create --name testnet testnet 172.16.42.0/24
neutron router-create r1 # a router is needed in order to get metadata service over network
neutron router-interface-add r1 testnet
openstack server create --key-name openstack_rsa --flavor m1.tiny --image cirros-0.3.3-x86_64 --nic net-id=$NETID --wait testvm1

exit

openstack keypair delete openstack_rsa
openstack server delete testvm1
neutron router-interface-delete r1 testnet
neutron router-delete r1
neutron subnet-delete testnet
neutron net-delete testnet