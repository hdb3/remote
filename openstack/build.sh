source creds
#variables
export VSUBNETNAME=testnet VNETNAME=testnet INTERNALNETWORK="172.16.42.0/24" VMNAME=testvm1 \
EXTERNALNETNAME=extnet EXTERNALSUBNETNAME=extsubnet PHYSICALNETWORK=external EXTERNALNETWORK="172.16.1.0/24" \
EXTERNALGW=172.16.1.1 EXTERNALSTART=172.16.1.10 EXTERNALEND=172.16.1.254 DNS=10.30.65.200 ROUTER=r1 \
ROUTEDNETNAME=routednet ROUTEDSUBNETNAME=routedsubnet ROUTEDROUTER=r2 ROUTEDNETWORK="10.10.10.0/24" ROUTEDEXTERNALGW="172.16.1.150" ROUTEDVM=vmr

# NATed metwork
neutron net-create $VNETNAME
neutron subnet-create --name $VSUBNETNAME $VNETNAME $INTERNALNETWORK
nova boot --flavor m1.small --image cirros-0.3.3-x86_64 --nic net-id=$(neutron net-list| awk "/ $VNETNAME / {print \$2}") --poll $VMNAME
neutron net-create $EXTERNALNETNAME --router:external --provider:physical_network $PHYSICALNETWORK --provider:network_type flat
neutron subnet-create --name $EXTERNALSUBNETNAME --dns-nameserver $DNS --enable-dhcp --gateway $EXTERNALGW --allocation-pool start=$EXTERNALSTART,end=$EXTERNALEND $EXTERNALNETNAME $EXTERNALNETWORK
neutron router-create $ROUTER
neutron router-interface-add $ROUTER $VSUBNETNAME
neutron router-gateway-set $ROUTER $EXTERNALNETNAME
IP=$(nova list | awk "/$VMNAME/ {sub(\".*=\",\"\",\$12); sub(\",\",\"\",\$12); print \$12}")
PORT=$(neutron port-list | awk " /$IP/ {print \$2}")
neutron floatingip-create --port-id $PORT $EXTERNALNETNAME

# routed network
neutron net-create $ROUTEDNETNAME
neutron subnet-create --name $ROUTEDSUBNETNAME $ROUTEDNETNAME $ROUTEDNETWORK
neutron router-create $ROUTEDROUTER
neutron router-interface-add $ROUTEDROUTER $ROUTEDSUBNETNAME
neutron router-gateway-set --disable-snat --fixed-ip ip_address=172.16.1.150 $ROUTEDROUTER $EXTERNALNETNAME
export NETID=`neutron net-list| awk '/ routed-net / {print $2}'`
nova boot --flavor m1.small --image cirros-0.3.3-x86_64 --nic net-id=$(neutron net-list| awk "/ $ROUTEDNETNAME / {print \$2}") --poll $ROUTEDVM

exit

nova delete $ROUTEDVM $VMNAME

# routed network
neutron router-gateway-clear $ROUTEDROUTER
neutron router-interface-delete $ROUTEDROUTER $ROUTEDSUBNETNAME
neutron router-delete $ROUTEDROUTER
neutron subnet-delete $ROUTEDSUBNETNAME
neutron net-delete $ROUTEDNETNAME

# NATed network
neutron router-gateway-clear $ROUTER
neutron router-interface-delete $ROUTER $VSUBNETNAME
neutron router-interface-delete $ROUTER $VSUBNETNAME
neutron router-delete $ROUTER
neutron subnet-delete $VSUBNETNAME
neutron net-delete $VNETNAME

#external network
neutron subnet-delete $EXTERNALSUBNETNAME
neutron net-delete $EXTERNALNETNAME
