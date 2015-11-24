#!/bin/bash -ev
source creds
neutron net-create testnet
export NETID=`neutron net-list| awk '/ testnet / {print $2}'`
neutron subnet-create --name testnet testnet 172.16.42.0/24
nova boot --flavor m1.small --image cirros-0.3.3-x86_64 --nic net-id=$NETID --poll testvm1
nova boot --flavor m1.small --image cirros-0.3.3-x86_64 --nic net-id=$NETID --poll testvm2
echo "nova delete testvm ; neutron subnet-delete testnet ; neutron net-delete testnet"
