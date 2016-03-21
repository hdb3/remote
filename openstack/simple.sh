#!/bin/bash -ev
source creds
openstack keypair create --public-key openstack_rsa.pub openstack_rsa
neutron net-create testnet
export NETID=`neutron net-list| awk '/ testnet / {print $2}'`
neutron subnet-create --name testnet testnet 172.16.42.0/24
neutron router-create r1 # a router is needed in order to get metadata service over network
neutron router-interface-add r1 testnet
openstack server create --key-name openstack_rsa --flavor m1.small --image cirros-0.3.3-x86_64 --nic net-id=$NETID --wait testvm1
#nova boot --flavor m1.small --image cirros-0.3.3-x86_64 --nic net-id=$NETID --poll testvm1
#nova boot --flavor m1.small --image cirros-0.3.3-x86_64 --nic net-id=$NETID --poll testvm2

exit

nova delete testvm1 testvm2
neutron router-interface-delete r1 testnet
neutron router-delete r1
neutron subnet-delete testnet
neutron net-delete testnet
