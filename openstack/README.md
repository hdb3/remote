# openstack

build various openstack cluster topologies, from 'all-in-one' single node to separate control/network/compute nodes with multiple instances of any role

In addition to the scripts invoked at build time, there are additional scripts which can be used to manage nested VMs once openstack is running:

+ simple.sh - this builds two VMs connected by a pure virtual network (the only way to contact these machines would be via console - VNC, etc...)

+ external.sh - a full network topology which allows exit to the outer virtual network and even the internet!

+ routed.sh - alternate topology which does not use NAT.  Requires an assigned, routable subnet.  Simplifies operations and is to be preferred when administratively practical.

# Pure virtual operation

In this mode VMs have no external reachability at all - the only network connectivity provided is to other VMs in the same virtual network.  It is possible to connect to the VMs via the virtual network for testing or troubleshooting, but only by command line magic on the relavant hypervisor host.
However, this configuration is the initial building block for all other operation modes, and is documented here for reference.
All of the variable elements for the script are exposed as environment variables in the script.
The script includes support for boooting a VM into the virtual environment.

## Script
>export VIRTNET="172.16.42.0/24" IMAGE=cirros-0.3.3-x86_64 FLAVOR=m1.small VNETNAME=net-virt VSUBNETNAME=subnet-virt VMNAME=vm1
>neutron net-create $NETNAME
>neutron subnet-create --name $VSUBNETNAME $VNETNAME $VIRTNET
>nova boot --flavor $FLAVOR  --image $IMAGE net-id=`neutron net-list| awk "/ $VNETNAME / {print $2}"` --poll $VMNAME

# Floating-IP / NAT operation
This mode is the default reccomendation for connecting external clients to virtualised services, i.e. enabling inbound connections for TCP or UDP or even just ICMP.
The configuration is implmented by overlaying a pure virtual network with additional decorations: principally a virtual router and another,external, OpenStack network.  The external network is typically predefined and often shared with other virtual networks which also require externally reachable endpoints.  The addressable IPs needed ('floating IPs') are a predefined, shared, resource allocated from the shared external network.  The configuration process has 3 phases - (1) define the virtual network - (2) define the external network - (3) connect the internal and external networks together.
In the script that follows variable elements are again exposed as environment variables.  The names are reused consistently and without redeclaration in subsequent scripts.
The variable $PHYSICALNETNAME corresponds to a variable defined in the Neutron configuration: openvswitch_agent.ini:[ovs]bridge_mappings, e.g.: "bridge_mappings = external:br-ex".
Other variable names are hopefully mostly self-explanatory, but see later for a full exposition...
## Script - define the external network
>export PHYSICALNETNAME="external" DNS="10.30.65.200" EXTERNALGW="172.16.1.1" EXTERNALNETWORK="172.16.1.0/24" \
> EXTERNALNETNAME="net-external" EXTERNALSUBNETNAME="subnet-external" \
> EXTERNALADDRSTART="172.16.1.128" EXTERNALADDREND="172.16.1.254"
>neutron net-create $EXTERNALNETNAME --router:external --provider:physical_network $PHYSICALNETNAME --provider:network_type flat
>neutron subnet-create --name $EXTERNALSUBNETNAME --dns-nameserver $DNS --enable-dhcp --gateway $EXTERNALGW --allocation-pool start=EXTERNALIPSTART,end=EXTERNALIPEND $EXTERNALNETNAME $EXTERNALNETWORK

## Script - interconnect the internal and external networks (NAT mode)
>export ROUTERNAME="r1"
>neutron router-create $ROUTERNAME
>neutron router-interface-add $ROUTERNAME $VNETNAME
>neutron router-gateway-set $ROUTERNAME $EXTERNALNETNAME

## Script - bind a floating IP for a VM host
>IP=$(nova list | awk "/$VMNAME/ {sub(\"$VNETNAME=\",\"\",\$12); sub(\",\",\"\",\$12); print \$12}")
>PORT=$(neutron port-list | awk " /$IP/ {print \$2}")
>neutron floatingip-create --port-id $PORT $EXTERNALNETNAME

# Routed non-NAT operation

Routed non-NAT operation requires internal and external network definitions largely identical to that required for the NATed 'floating IP' model.  The phases and operations are as defined for Floating-IP / NAT operation, the difference is that the IP subnet used to creatre the virtual network should correspond to the externally routable address range, and the configuration for the connection between external and internal networks specifies a non-NAT mode, and requires explicit assignment of the externally reachable gateway address, which must lie in the subnet associated with the external network.

In the script that follows the additional parameter required is the IP address of the router which is designated in the external network routing scheme for reaching the virtual network.
Only the line "neutron router-gateway-set" changes.
## Script - interconnect the internal and external networks (Routed non-NAT mode)

>export ROUTERNAME="r1" EXTERNALNEXTHOP="172.16.1.150"
>neutron router-create $ROUTERNAME
>neutron router-interface-add $ROUTERNAME $VNETNAME
>neutron router-gateway-set --disable-snat --fixed-ip ip_address=$EXTERNALNEXTHOP $ROUTERNAME $EXTERNALNETNAME

# Direct external network configuration
It is possible to avoid entirely the use of internal virtual networks and routers.  The external networks defined in the first configuration example can also be used directly, subject to caveats on DHCP usage and metadata service.  However, this would require use of the 'config drive' mechanism to inject metadata into VMs at start-up.
# DHCP, meta-data and other stories
The scripts presented enable DHCP on all virtual networks: this may easily be disabled, however if VMs do not use their OpenStack configured addresses, acquired either via DHCP or metadata, then OpenStack firewall security would block useful operation unless disabled.
DHCP aoperation for pure external networks is more problematic, if a physical DHCP server is also present, however it is also possible, as long as OpenStack firewall security is disabled.
