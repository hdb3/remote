
for f in /etc/neutron/neutron.conf /etc/neutron/plugins/ml2/ml2_conf.ini ; do
  sed -i -e "/^#/d" $f
  sed -i -e "/^$/d" $f
done

crudini --set --verbose /etc/neutron/neutron.conf database connection mysql+pymsql://neutron:$DBPASSWD@$CONTROLLER_IP/neutron

crudini --set --verbose /etc/neutron/neutron.conf DEFAULT rpc_backend rabbit
crudini --set --verbose /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
crudini --set --verbose /etc/neutron/neutron.conf DEFAULT core_plugin ml2
crudini --set --verbose /etc/neutron/neutron.conf DEFAULT service_plugins router
crudini --set --verbose /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips True
crudini --set --verbose /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
crudini --set --verbose /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True
crudini --set --verbose /etc/neutron/neutron.conf DEFAULT nova_url  http://$CONTROLLER_IP:8774/v2

crudini --set --verbose /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_host $CONTROLLER_IP
crudini --set --verbose /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_userid $RABBIT_USER
crudini --set --verbose /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_password $RABBIT_PASSWORD

crudini --set --verbose /etc/neutron/neutron.conf nova auth_url  http://$CONTROLLER_IP:35357
crudini --set --verbose /etc/neutron/neutron.conf nova auth_plugin password
crudini --set --verbose /etc/neutron/neutron.conf nova project_domain_id default
crudini --set --verbose /etc/neutron/neutron.conf nova user_domain_id default
crudini --set --verbose /etc/neutron/neutron.conf nova region_name RegionOne
crudini --set --verbose /etc/neutron/neutron.conf nova project_name service
crudini --set --verbose /etc/neutron/neutron.conf nova username nova
crudini --set --verbose /etc/neutron/neutron.conf nova password $SERVICE_PWD

crudini --set --verbose /etc/neutron/neutron.conf keystone_authtoken auth_uri http://$CONTROLLER_IP:5000
crudini --set --verbose /etc/neutron/neutron.conf keystone_authtoken auth_url http://$CONTROLLER_IP:35357
crudini --set --verbose /etc/neutron/neutron.conf keystone_authtoken auth_plugin password
crudini --set --verbose /etc/neutron/neutron.conf keystone_authtoken project_domain_id default
crudini --set --verbose /etc/neutron/neutron.conf keystone_authtoken user_domain_id default
crudini --set --verbose /etc/neutron/neutron.conf keystone_authtoken project_name service
crudini --set --verbose /etc/neutron/neutron.conf keystone_authtoken username neutron
crudini --set --verbose /etc/neutron/neutron.conf keystone_authtoken password $SERVICE_PWD


if [[ $MY_ROLE =~ "controller" ]] ; then
  echo "running neutron controller node setup"

  ln -fs /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
  crudini --set --verbose /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,vxlan
  crudini --set --verbose /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan
  crudini --set --verbose /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers linuxbridge,l2population
  crudini --set --verbose /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers  port_security
  crudini --set --verbose /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks provider
  crudini --set --verbose /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1:1000
  crudini --set --verbose /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True

  crudini --set --verbose /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings provider:$EXTERNAL_PORT
  crudini --set --verbose /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan True
  crudini --set --verbose /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan local_ip $TUNNEL_IP
  crudini --set --verbose /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan l2_population True
  crudini --set --verbose /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_security_group True
  crudini --set --verbose /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

  crudini --set --verbose /etc/neutron/l3_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.BridgeInterfaceDriver
  crudini --set --verbose /etc/neutron/l3_agent.ini DEFAULT external_network_bridge br-ex

  crudini --set --verbose /etc/neutron/dhcp_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.BridgeInterfaceDriver
  crudini --set --verbose /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
  crudini --set --verbose /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata True

  source creds
  openstack user create --domain default --password $SERVICE_PWD neutron
  openstack role add --project service --user neutron admin
  openstack service create --name neutron --description "OpenStack Networking" network
  openstack endpoint create --region RegionOne network public http://$CONTROLLER_IP:9696
  openstack endpoint create --region RegionOne network internal http://$CONTROLLER_IP:9696
  openstack endpoint create --region RegionOne network admin http://$CONTROLLER_IP:9696
  su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
  systemctl restart $CONTROLLER_NOVA_SERVICES
  systemctl enable --now $CONTROLLER_NEUTRON_SERVICES
fi

if [[ $MY_ROLE =~ "compute" ]] ; then
  systemctl enable --now $COMPUTE_NEUTRON_SERVICES
fi
