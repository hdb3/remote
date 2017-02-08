
for f in /etc/neutron/neutron.conf /etc/neutron/plugins/ml2/ml2_conf.ini ; do
  sed -i -e "/^#/d" $f
  sed -i -e "/^$/d" $f
done

if [ -n "$TUNNEL_SUBNET" ] ; then
  TUNNEL_IP=$(./subnet.py $TUNNEL_SUBNET)
else
  TUNNEL_IP="ERROR"
fi
if [[ $TUNNEL_IP == "ERROR" ]] ; then TUNNEL_IP=$MY_IP ; fi

crudini --set --verbose /etc/neutron/neutron.conf database connection mysql+pymysql://neutron:$DBPASSWD@$CONTROLLER_IP/neutron

crudini --set --verbose  /etc/neutron/neutron.conf DEFAULT api_workers 1
crudini --set --verbose  /etc/neutron/neutron.conf DEFAULT rpc_backend rabbit
crudini --set --verbose  /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
crudini --set --verbose  /etc/neutron/neutron.conf DEFAULT core_plugin ml2
crudini --set --verbose  /etc/neutron/neutron.conf DEFAULT service_plugins router
crudini --set --verbose  /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips True
crudini --set --verbose  /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
crudini --set --verbose  /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True
crudini --set --verbose  /etc/neutron/neutron.conf DEFAULT nova_url  http://$CONTROLLER_IP:8774/v2

crudini --set --verbose  /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_host $CONTROLLER_IP
crudini --set --verbose  /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set --verbose  /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_password $SERVICE_PWD

crudini --set --verbose  /etc/neutron/neutron.conf nova auth_url  http://$CONTROLLER_IP:35357
crudini --set --verbose  /etc/neutron/neutron.conf nova auth_type password
crudini --set --verbose  /etc/neutron/neutron.conf nova project_domain_name default
crudini --set --verbose  /etc/neutron/neutron.conf nova user_domain_name default
crudini --set --verbose  /etc/neutron/neutron.conf nova region_name RegionOne
crudini --set --verbose  /etc/neutron/neutron.conf nova project_name service
crudini --set --verbose  /etc/neutron/neutron.conf nova username nova
crudini --set --verbose  /etc/neutron/neutron.conf nova password $SERVICE_PWD

crudini --set --verbose  /etc/neutron/neutron.conf keystone_authtoken auth_uri http://$CONTROLLER_IP:5000
crudini --set --verbose  /etc/neutron/neutron.conf keystone_authtoken auth_url http://$CONTROLLER_IP:35357
crudini --set --verbose  /etc/neutron/neutron.conf keystone_authtoken memcached_servers $CONTROLLER_IP:11211
crudini --set --verbose  /etc/neutron/neutron.conf keystone_authtoken auth_type password
crudini --set --verbose  /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
crudini --set --verbose  /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
crudini --set --verbose  /etc/neutron/neutron.conf keystone_authtoken project_name service
crudini --set --verbose  /etc/neutron/neutron.conf keystone_authtoken username neutron
crudini --set --verbose  /etc/neutron/neutron.conf keystone_authtoken password $SERVICE_PWD





  crudini --set --verbose /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_ip $CONTROLLER_IP
  crudini --set --verbose /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret $META_PWD
  crudini --set --verbose /etc/neutron/metadata_agent.ini DEFAULT metadata_workers 1
  ln -fs /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
  crudini --set --verbose  /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,gre,vxlan
  crudini --set --verbose  /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types gre
  crudini --set --verbose  /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks $EXTERNAL_PORT
  crudini --set --verbose  /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vlan network_vlan_ranges vlan
  crudini --set --verbose  /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch
  crudini --set --verbose  /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_gre tunnel_id_ranges 1:1000
  crudini --set --verbose  /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True
  crudini --set --verbose  /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True

if [[ $MY_ROLE =~ "controller" ]] ; then
  echo "running neutron controller node setup"

  source creds
  openstack user create --domain default --password $SERVICE_PWD neutron
  openstack role add --project service --user neutron admin
  openstack service create --name neutron --description "OpenStack Networking" network
  openstack endpoint create --region RegionOne network public http://$CONTROLLER_IP:9696
  openstack endpoint create --region RegionOne network internal http://$CONTROLLER_IP:9696
  openstack endpoint create --region RegionOne network admin http://$CONTROLLER_IP:9696
  su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
  systemctl restart openstack-nova-api openstack-nova-scheduler openstack-nova-conductor
  systemctl enable neutron-server
  systemctl restart neutron-server
fi

if [[ $MY_ROLE =~ "compute" || $MY_ROLE =~ "network" ]] ; then
  echo "running neutron compute/network node setup"
  crudini --set --verbose  /etc/neutron/dhcp_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
  crudini --set --verbose  /etc/neutron/l3_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
  crudini --set --verbose  /etc/neutron/l3_agent.ini DEFAULT gateway_external_network_id
  crudini --set --verbose  /etc/neutron/l3_agent.ini DEFAULT external_network_bridge
  # crudini --set --verbose  /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs local_ip $(./subnet.py $TUNNEL_SUBNET)
  crudini --set --verbose  /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs local_ip $TUNNEL_IP
  crudini --set --verbose  /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs ovsdb_interface native
  crudini --set --verbose  /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup enable_security_group True
  crudini --set --verbose  /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup enable_ipset True
  crudini --set --verbose  /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup firewall_driver neutron.agent.firewall.NoopFirewallDriver
  # crudini --set --verbose  /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
  crudini --set --verbose  /etc/neutron/plugins/ml2/openvswitch_agent.ini agent tunnel_types gre
  echo 'net.ipv4.conf.all.rp_filter=0' >> /etc/sysctl.conf
  echo 'net.ipv4.conf.default.rp_filter=0' >> /etc/sysctl.conf
  # echo 'net.bridge.bridge-nf-call-iptables=1' >> /etc/sysctl.conf
  # echo 'net.bridge.bridge-nf-call-ip6tables=1' >> /etc/sysctl.conf
  sysctl -p
fi


# if [[ $MY_ROLE =~ "network" ]] ; then
# the following needed if external networks are needed on compute nodes (and probably also for distributed virtual routers)
EXTERNAL_BRIDGE=br-${EXTERNAL_PORT}
VLAN_BRIDGE=br-${VLAN_PORT}
if [[ $MY_ROLE =~ "compute" || $MY_ROLE =~ "network" ]] ; then
  systemctl restart openvswitch
  if [[ -n "$EXTERNAL_PORT" && -n "$VLAN_PORT" ]] ; then
    mappings="${EXTERNAL_PORT}:${EXTERNAL_BRIDGE},vlan:${VLAN_BRIDGE}"
  elif [[ -n "$VLAN_PORT" ]] ; then
    mappings="vlan:${VLAN_BRIDGE}"
  elif [[ -n "$EXTERNAL_PORT" ]] ; then
    mappings="${EXTERNAL_PORT}:${EXTERNAL_BRIDGE}"
  fi
  crudini --set --verbose  /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs bridge_mappings "$mappings"
  set +e
  if [ -n "$EXTERNAL_PORT" ] ; then
    ip link set dev $EXTERNAL_PORT up
    ovs-vsctl --may-exist add-br ${EXTERNAL_BRIDGE}
    ovs-vsctl --may-exist add-port ${EXTERNAL_BRIDGE} $EXTERNAL_PORT
    ip link set dev $EXTERNAL_BRIDGE up
  fi
  if [ -n "$VLAN_PORT" ] ; then
    ip link set dev $VLAN_PORT up
    ovs-vsctl --may-exist add-br ${VLAN_BRIDGE}
    ovs-vsctl --may-exist add-port ${VLAN_BRIDGE} $VLAN_PORT -- set port $VLAN_PORT vlan_mode=trunk
    ip link set dev $VLAN_BRIDGE up
  fi
  set -e
  crudini --set --verbose /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret $META_PWD
  crudini --set --verbose /etc/neutron/metadata_agent.ini DEFAULT auth_url http://$CONTROLLER_IP:5000/v2.0
  crudini --set --verbose /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_ip $CONTROLLER_IP
   #NETWORK_SERVICES="openvswitch neutron-openvswitch-agent neutron-dhcp-agent neutron-l3-agent neutron-metadata-agent"
  systemctl enable $NETWORK_SERVICES neutron-ovs-cleanup ; systemctl restart $NETWORK_SERVICES
fi

if [[ $MY_ROLE =~ "compute" ]] ; then
   #NETWORK_SERVICES="openvswitch neutron-openvswitch-agent "
  systemctl enable $NETWORK_SERVICES ; systemctl restart $NETWORK_SERVICES
fi
