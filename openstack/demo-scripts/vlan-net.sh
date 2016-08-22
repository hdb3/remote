# This script will create a vlan trunked networkfor a client VM
# and boot a sample VM on such a network
#
# This allows a large number of seprated networks to be configured based only on
# online configuration of OpenStack (no updates to OVS or OpenStack .ini files)
#
# It relies on an OpenStack / OVS config with complemetary configuration:
#    * the OpenStack VLAN provider network is named 'vlan'
#    * OVS has a matching bridge name, e.g. br-vlan, if the bridge_mapping stanza in 
#      section 'ovs' in 'openvswitch_agent.ini' contains 'vlan:br-vlan'

#variables
VLAN=42 PHYSICALNETWORK=vlan EXNET="192.168.42" VMNAME=testvm1
EXTERNALNETNAME=extnet EXTERNALSUBNETNAME=extsubnet EXTERNALNETWORK="$EXNET.0/24" \
EXTERNALGW=$EXNET.42 EXTERNALSTART=$EXNET.170 EXTERNALEND=$EXNET.179 DNS=${EXNET}.200

# external network
neutron net-create $EXTERNALNETNAME --router:external --provider:segmentation_id $VLAN --provider:physical_network $PHYSICALNETWORK --provider:network_type vlan --shared
neutron subnet-create --name $EXTERNALSUBNETNAME --dns-nameserver $DNS --enable-dhcp --gateway $EXTERNALGW --allocation-pool start=$EXTERNALSTART,end=$EXTERNALEND $EXTERNALNETNAME $EXTERNALNETWORK

openstack server create --flavor m1.small --image cirros-0.3.3-x86_64 --nic net-id=$(neutron net-list| awk "/ $EXTERNALNETNAME / {print \$2}") --wait $VMNAME

exit

openstack server delete $VMNAME
neutron subnet-delete $EXTERNALSUBNETNAME
neutron net-delete $EXTERNALNETNAME
