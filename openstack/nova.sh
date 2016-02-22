
if [[ $MY_ROLE =~ "controller" ||  $MY_ROLE =~ "compute" ]] ; then

  sed -i -e "/^#/d" /etc/nova/nova.conf
  sed -i -e "/^$/d" /etc/nova/nova.conf

  crudini --set --verbose /etc/nova/nova.conf database connection mysql://nova:$DBPASSWD@$CONTROLLER_IP/nova

  crudini --set --verbose /etc/nova/nova.conf DEFAULT rpc_backend rabbit
  crudini --set --verbose /etc/nova/nova.conf DEFAULT auth_strategy keystone
  crudini --set --verbose /etc/nova/nova.conf DEFAULT my_ip $MY_IP
  crudini --set --verbose /etc/nova/nova.conf DEFAULT vncserver_listen 0.0.0.0
  crudini --set --verbose /etc/nova/nova.conf DEFAULT vncserver_proxyclient_address $MY_IP
  crudini --set --verbose /etc/nova/nova.conf DEFAULT novncproxy_base_url  http://$CONTROLLER_IP:6080/vnc_auto.html
  crudini --set --verbose /etc/nova/nova.conf DEFAULT network_api_class nova.network.neutronv2.api.API
  crudini --set --verbose /etc/nova/nova.conf DEFAULT security_group_api neutron
  crudini --set --verbose /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver
  crudini --set --verbose /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
  # crudini --set --verbose /etc/nova/nova.conf libvirt qemu
  crudini --set --verbose /etc/nova/nova.conf libvirt virt_type qemu

  crudini --set --verbose /etc/nova/nova.conf oslo_messaging_rabbit rabbit_host $CONTROLLER_IP
  crudini --set --verbose /etc/nova/nova.conf oslo_messaging_rabbit rabbit_userid openstack
  crudini --set --verbose /etc/nova/nova.conf oslo_messaging_rabbit rabbit_password $SERVICE_PWD

  crudini --set --verbose /etc/nova/nova.conf keystone_authtoken auth_uri http://$CONTROLLER_IP:5000
  crudini --set --verbose /etc/nova/nova.conf keystone_authtoken auth_url http://$CONTROLLER_IP:35357
  crudini --set --verbose /etc/nova/nova.conf keystone_authtoken auth_plugin password
  crudini --set --verbose /etc/nova/nova.conf keystone_authtoken project_domain_id default
  crudini --set --verbose /etc/nova/nova.conf keystone_authtoken user_domain_id default
  crudini --set --verbose /etc/nova/nova.conf keystone_authtoken project_name service
  crudini --set --verbose /etc/nova/nova.conf keystone_authtoken username nova
  crudini --set --verbose /etc/nova/nova.conf keystone_authtoken password $SERVICE_PWD

  crudini --set --verbose /etc/nova/nova.conf glance host $CONTROLLER_IP

  crudini --set --verbose /etc/nova/nova.conf neutron url http://$CONTROLLER_IP:9696
  crudini --set --verbose /etc/nova/nova.conf neutron auth_strategy keystone
  crudini --set --verbose /etc/nova/nova.conf neutron admin_auth_url http://$CONTROLLER_IP:35357/v2.0
  crudini --set --verbose /etc/nova/nova.conf neutron admin_tenant_name service
  crudini --set --verbose /etc/nova/nova.conf neutron admin_username neutron
  crudini --set --verbose /etc/nova/nova.conf neutron admin_password $SERVICE_PWD
  crudini --set --verbose /etc/nova/nova.conf neutron service_metadata_proxy True
  crudini --set --verbose /etc/nova/nova.conf neutron metadata_proxy_shared_secret meta123
fi

if [[ $MY_ROLE =~ "controller" ]] ; then
  echo "running controller node setup"
  source creds
  openstack user create --password $SERVICE_PWD nova
  openstack role add --project service --user nova admin
  openstack service create --name nova --description "OpenStack Compute" compute
  openstack endpoint create  --publicurl http://$CONTROLLER_IP:8774/v2/%\(tenant_id\)s --internalurl http://$CONTROLLER_IP:8774/v2/%\(tenant_id\)s --adminurl http://$CONTROLLER_IP:8774/v2/%\(tenant_id\)s --region RegionOne compute
  su -s /bin/sh -c "nova-manage db sync" nova
   #CONTROLLER_SERVICES="openstack-nova-api openstack-nova-cert openstack-nova-consoleauth openstack-nova-scheduler openstack-nova-conductor openstack-nova-novncproxy"
  systemctl enable $CONTROLLER_SERVICES
  systemctl start $CONTROLLER_SERVICES
fi

if [[ $MY_ROLE =~ "compute" ]] ; then
  echo "running compute node setup"
  echo 'net.ipv4.conf.all.rp_filter=0' >> /etc/sysctl.conf
  echo 'net.ipv4.conf.default.rp_filter=0' >> /etc/sysctl.conf
  # echo 'net.bridge.bridge-nf-call-iptables=1' >> /etc/sysctl.conf
  # echo 'net.bridge.bridge-nf-call-ip6tables=1' >> /etc/sysctl.conf
  sysctl -p
  crudini --set --verbose /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp
   #COMPUTE_SERVICES="openvswitch libvirtd openstack-nova-compute"
  systemctl enable $COMPUTE_SERVICES
  systemctl start $COMPUTE_SERVICES
fi
