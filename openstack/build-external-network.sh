# this script builds ALL of the required objects for routed external networking in OpenStack
NETNAME="net67" EXGW="10.30.65.1" LOCALGW="10.30.65.11" EXNET="10.30.65.0/24" LOCALNET="10.30.67.0/24" DNS="10.30.65.200" OSEXNET="external"
#create the external network
neutron net-create ext-net --router:external --provider:physical_network $OSEXNET --provider:network_type flat
neutron subnet-create --name ext-net --disable-dhcp --gateway $EXGW ext-net $EXNET
#create the internal network
neutron net-create $NETNAME --shared
neutron subnet-create --dns-nameserver=$DNS --name $NETNAME $NETNAME $LOCALNET
#bind the networks with a router
neutron router-create $NETNAME
neutron router-interface-add $NETNAME $NETNAME
neutron router-gateway-set --disable-snat --fixed-ip ip_address=$LOCALGW $NETNAME ext-net
