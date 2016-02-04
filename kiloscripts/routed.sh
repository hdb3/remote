neutron net-create routed-net
neutron subnet-create --name routed-net routed-net 10.10.10.0/24
neutron router-create routed-net 
neutron router-interface-add routed-net routed-net
neutron router-gateway-set --disable-snat --fixed-ip ip_address=172.16.1.150 routed-net ext-net
export NETID=`neutron net-list| awk '/ routed-net / {print $2}'`
nova boot --flavor m1.small --image cirros-0.3.3-x86_64 --nic net-id=$NETID --poll testvm99
exit
neutron router-gateway-clear routed-net ext-net
neutron router-interface-delete routed-net routed-net
neutron router-delete routed-net
neutron net-delete routed-net
