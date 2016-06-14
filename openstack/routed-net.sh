source creds
#variables
EXNET=10.30.65 INNET=10.30.67
export VSUBNETNAME=testnet VNETNAME=testnet INTERNALNETWORK="172.16.42.0/24" VMNAME=testvm1 \
EXTERNALNETNAME=extnet EXTERNALSUBNETNAME=extsubnet PHYSICALNETWORK=external EXTERNALNETWORK="$EXNET.0/24" \
EXTERNALGW=$EXNET.1 EXTERNALSTART=$EXNET.170 EXTERNALEND=$EXNET.179 DNS=10.30.65.200 ROUTER=r1 \
ROUTEDNETNAME=routednet ROUTEDSUBNETNAME=routedsubnet ROUTEDROUTER=r2 ROUTEDNETWORK="${INNET}.0/24" ROUTEDEXTERNALGW="$EXNET.11" ROUTEDVM=vmr

# external metwork
neutron net-create $EXTERNALNETNAME --router:external --provider:physical_network $PHYSICALNETWORK --provider:network_type flat
neutron subnet-create --name $EXTERNALSUBNETNAME --dns-nameserver $DNS --enable-dhcp --gateway $EXTERNALGW --allocation-pool start=$EXTERNALSTART,end=$EXTERNALEND $EXTERNALNETNAME $EXTERNALNETWORK

# routed network
neutron net-create $ROUTEDNETNAME
neutron subnet-create --name $ROUTEDSUBNETNAME $ROUTEDNETNAME $ROUTEDNETWORK
neutron router-create $ROUTEDROUTER
neutron router-interface-add $ROUTEDROUTER $ROUTEDSUBNETNAME
neutron router-gateway-set --disable-snat --fixed-ip ip_address=$ROUTEDEXTERNALGW $ROUTEDROUTER $EXTERNALNETNAME
export NETID=`neutron net-list| awk '/ routed-net / {print $2}'`
openstack server create --flavor m1.small --image cirros-0.3.3-x86_64 --nic net-id=$(neutron net-list| awk "/ $ROUTEDNETNAME / {print \$2}") --wait $ROUTEDVM

exit

openstack server delete $ROUTEDVM $VMNAME

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
