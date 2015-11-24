
for f in /etc/neutron/neutron.conf /etc/neutron/plugins/ml2/ml2_conf.ini ; do
  sed -i -e "/^#/d" $f
  sed -i -e "/^$/d" $f
done

crudini --set --verbose  /etc/neutron/neutron.conf database connection mysql://neutron:$DBPASSWD@$CONTROLLER_IP/neutron

# SERVICE_TENANT_ID=$(keystone tenant-list | awk '/ service / {print $2}')

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
crudini --set --verbose  /etc/neutron/neutron.conf nova auth_plugin password
crudini --set --verbose  /etc/neutron/neutron.conf nova project_domain_id default
crudini --set --verbose  /etc/neutron/neutron.conf nova user_domain_id default
crudini --set --verbose  /etc/neutron/neutron.conf nova region_name RegionOne
crudini --set --verbose  /etc/neutron/neutron.conf nova project_name service
crudini --set --verbose  /etc/neutron/neutron.conf nova username nova
crudini --set --verbose  /etc/neutron/neutron.conf nova password $SERVICE_PWD

crudini --set --verbose  /etc/neutron/neutron.conf keystone_authtoken auth_uri http://$CONTROLLER_IP:5000
crudini --set --verbose  /etc/neutron/neutron.conf keystone_authtoken auth_url http://$CONTROLLER_IP:35357
crudini --set --verbose  /etc/neutron/neutron.conf keystone_authtoken auth_plugin password
crudini --set --verbose  /etc/neutron/neutron.conf keystone_authtoken project_domain_id default
crudini --set --verbose  /etc/neutron/neutron.conf keystone_authtoken user_domain_id default
crudini --set --verbose  /etc/neutron/neutron.conf keystone_authtoken project_name service
crudini --set --verbose  /etc/neutron/neutron.conf keystone_authtoken username neutron
crudini --set --verbose  /etc/neutron/neutron.conf keystone_authtoken password $SERVICE_PWD





if [[ $MY_ROLE =~ "controller" ]] ; then
  echo "running neutron controller node setup"

  ln -fs /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
  crudini --set --verbose  /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,gre,vxlan
  crudini --set --verbose  /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types gre
  crudini --set --verbose  /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch
  crudini --set --verbose  /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_gre tunnel_id_ranges 1:1000
  crudini --set --verbose  /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True
  crudini --set --verbose  /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True

  source creds
  openstack user create --password $SERVICE_PWD neutron
  openstack role add --project service --user neutron admin
  openstack service create --name neutron --description "OpenStack Networking" network
  openstack endpoint create --publicurl http://$CONTROLLER_IP:9696 --internalurl http://$CONTROLLER_IP:9696 --adminurl http://$CONTROLLER_IP:9696 --region RegionOne network
  su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
  systemctl restart openstack-nova-api openstack-nova-scheduler openstack-nova-conductor
  systemctl enable neutron-server
  systemctl restart neutron-server
fi

if [[ $MY_ROLE =~ "compute" || $MY_ROLE =~ "network" ]] ; then
  echo "running neutron compute/network node setup"
  TUNNEL_IP=$(./subnet.py $TUNNEL_SUBNET)
  if [[ $TUNNEL_IP == "ERROR" ]] ; then TUNNEL_IP=$MY_IP ; fi
  crudini --set --verbose  /etc/neutron/dhcp_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
  crudini --set --verbose  /etc/neutron/l3_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
  # crudini --set --verbose  /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini ovs local_ip $(./subnet.py $TUNNEL_SUBNET)
  crudini --set --verbose  /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini ovs local_ip $TUNNEL_IP
  crudini --set --verbose  /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini securitygroup enable_security_group True
  crudini --set --verbose  /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini securitygroup enable_ipset True
  crudini --set --verbose  /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini securitygroup firewall_driver neutron.agent.firewall.NoopFirewallDriver
  # crudini --set --verbose  /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
  crudini --set --verbose  /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini agent tunnel_types gre
  echo 'net.ipv4.conf.all.rp_filter=0' >> /etc/sysctl.conf
  echo 'net.ipv4.conf.default.rp_filter=0' >> /etc/sysctl.conf
  # echo 'net.bridge.bridge-nf-call-iptables=1' >> /etc/sysctl.conf
  # echo 'net.bridge.bridge-nf-call-ip6tables=1' >> /etc/sysctl.conf
  sysctl -p
fi


# if [[ $MY_ROLE =~ "network" ]] ; then
# the following needed if external networks are needed on compute nodes (and probably also for distributed virtual routers)
if [[ $MY_ROLE =~ "compute" || $MY_ROLE =~ "network" ]] ; then
  systemctl restart openvswitch
  ip link set dev $EXTERNAL_PORT up
  ovs-vsctl --may-exist add-br br-ex
  ovs-vsctl --may-exist add-port br-ex $EXTERNAL_PORT
  crudini --set --verbose  /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini ovs bridge_mappings external:br-ex
   #NETWORK_SERVICES="openvswitch neutron-openvswitch-agent neutron-dhcp-agent neutron-l3-agent neutron-metadata-agent"
  systemctl enable $NETWORK_SERVICES neutron-ovs-cleanup ; systemctl restart $NETWORK_SERVICES
fi

if [[ $MY_ROLE =~ "compute" ]] ; then
   #NETWORK_SERVICES="openvswitch neutron-openvswitch-agent "
  systemctl enable $NETWORK_SERVICES ; systemctl restart $NETWORK_SERVICES
fi
