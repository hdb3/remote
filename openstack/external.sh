#!/bin/bash -ev
#
# this script assumes that the script 'simple.sh' has already been run
# 'simple.sh' creates tow VMs and a virtual network and router, r1
#
# if that router did not already exist then the commented out lines of code could be used to do so
#
source creds
neutron net-create ext-net --router:external --provider:physical_network external --provider:network_type flat
neutron subnet-create --name ext-net --dns-nameserver 10.30.65.200 --enable-dhcp --gateway 172.16.1.1 --allocation-pool start=172.16.1.128,end=172.16.1.254 ext-net 172.16.1.0/24
# neutron router-create ext-net
# neutron router-interface-add ext-net testnet
# neutron router-gateway-set ext-net ext-net
neutron router-gateway-set r1 ext-net

for VM in testvm1 testvm2
  do echo $VM
  IP=$(nova list | awk "/$VM/ {sub(\".*=\",\"\",\$12); sub(\",\",\"\",\$12); print \$12}")
  PORT=$(neutron port-list | awk " /$IP/ {print \$2}")
  neutron floatingip-create --port-id $PORT ext-net
done

exit

for FIP in $(neutron floatingip-list | awk '!/+/ && !/id/ {print $2}')
  do neutron floatingip-delete $FIP
done

neutron router-gateway-clear ext-net
neutron router-interface-delete ext-net testnet
neutron router-delete ext-net
neutron subnet-delete ext-net
neutron net-delete ext-net
