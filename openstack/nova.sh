
if [[ $MY_ROLE =~ "controller" ||  $MY_ROLE =~ "compute" ]] ; then

  sed -i -e "/^#/d" /etc/nova/nova.conf
  sed -i -e "/^$/d" /etc/nova/nova.conf

  crudini --set --verbose /etc/nova/nova.conf DEFAULT enabled_apis osapi_compute,metadata
  crudini --set --verbose /etc/nova/nova.conf api_database connection mysql+pymysql://nova:$DBPASSWD@$CONTROLLER_IP/nova_api
  crudini --set --verbose /etc/nova/nova.conf database connection mysql+pymysql://nova:$DBPASSWD@$CONTROLLER_IP/nova
  crudini --set --verbose /etc/nova/nova.conf DEFAULT osapi_compute_workers 1
  crudini --set --verbose /etc/nova/nova.conf DEFAULT metadata_workers 1
  crudini --set --verbose /etc/nova/nova.conf conductor workers 1


  crudini --set --verbose /etc/nova/nova.conf DEFAULT use_neutron True
  crudini --set --verbose /etc/nova/nova.conf DEFAULT rpc_backend rabbit
  crudini --set --verbose /etc/nova/nova.conf DEFAULT auth_strategy keystone
  crudini --set --verbose /etc/nova/nova.conf DEFAULT my_ip $MY_IP
  crudini --set --verbose /etc/nova/nova.conf vnc vncserver_listen 0.0.0.0
  crudini --set --verbose /etc/nova/nova.conf vnc vncserver_proxyclient_address $MY_IP
  crudini --set --verbose /etc/nova/nova.conf vnc novncproxy_base_url http://$CONTROLLER_IP:6080/vnc_auto.html
  crudini --set --verbose /etc/nova/nova.conf DEFAULT network_api_class nova.network.neutronv2.api.API
  crudini --set --verbose /etc/nova/nova.conf DEFAULT security_group_api neutron
  crudini --set --verbose /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver
  crudini --set --verbose /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

  crudini --set --verbose /etc/nova/nova.conf glance api_servers http://$CONTROLLER_IP:9292
  crudini --set --verbose /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

  if [[ -z "$VIRTMODE" ]] ; then
    crudini --set --verbose /etc/nova/nova.conf libvirt virt_type kvm
  else
    crudini --set --verbose /etc/nova/nova.conf libvirt virt_type $VIRTMODE
  fi

  crudini --set --verbose /etc/nova/nova.conf oslo_messaging_rabbit rabbit_host $CONTROLLER_IP
  crudini --set --verbose /etc/nova/nova.conf oslo_messaging_rabbit rabbit_userid openstack # really should make 'openstack' a variable like $RABBIT_USERID
  crudini --set --verbose /etc/nova/nova.conf oslo_messaging_rabbit rabbit_password $SERVICE_PWD

  crudini --set --verbose /etc/nova/nova.conf keystone_authtoken auth_uri http://$CONTROLLER_IP:5000
  crudini --set --verbose /etc/nova/nova.conf keystone_authtoken auth_url http://$CONTROLLER_IP:35357
  crudini --set --verbose /etc/nova/nova.conf keystone_authtoken memcached_servers $CONTROLLER_IP:11211
  crudini --set --verbose /etc/nova/nova.conf keystone_authtoken auth_type password
  crudini --set --verbose /etc/nova/nova.conf keystone_authtoken project_domain_name default
  crudini --set --verbose /etc/nova/nova.conf keystone_authtoken user_domain_name default
  crudini --set --verbose /etc/nova/nova.conf keystone_authtoken project_name service
  crudini --set --verbose /etc/nova/nova.conf keystone_authtoken username nova
  crudini --set --verbose /etc/nova/nova.conf keystone_authtoken password $SERVICE_PWD

  crudini --set --verbose /etc/nova/nova.conf neutron url http://$CONTROLLER_IP:9696
  crudini --set --verbose /etc/nova/nova.conf neutron auth_url http://$CONTROLLER_IP:35357

  crudini --set --verbose /etc/nova/nova.conf neutron auth_type password
  crudini --set --verbose /etc/nova/nova.conf neutron project_domain_name default
  crudini --set --verbose /etc/nova/nova.conf neutron user_domain_name default
  crudini --set --verbose /etc/nova/nova.conf neutron region_name RegionOne
  crudini --set --verbose /etc/nova/nova.conf neutron project_name service
  crudini --set --verbose /etc/nova/nova.conf neutron username neutron
  crudini --set --verbose /etc/nova/nova.conf neutron password $SERVICE_PWD
  crudini --set --verbose /etc/nova/nova.conf neutron service_metadata_proxy True
  crudini --set --verbose /etc/nova/nova.conf neutron metadata_proxy_shared_secret $META_PWD
fi

if [[ $MY_ROLE =~ "controller" ]] ; then
  echo "running controller node setup"
  source creds
  openstack user create --domain default --password $SERVICE_PWD nova
  openstack role add --project service --user nova admin
  openstack service create --name nova --description "OpenStack Compute" compute
  openstack endpoint create --region RegionOne compute public http://$CONTROLLER_IP:8774/v2.1/%\(tenant_id\)s
  openstack endpoint create --region RegionOne compute internal http://$CONTROLLER_IP:8774/v2.1/%\(tenant_id\)s
  openstack endpoint create --region RegionOne compute admin http://$CONTROLLER_IP:8774/v2.1/%\(tenant_id\)s
  crudini --set --verbose /etc/nova/nova.conf cinder os_region_name RegionOne
  su -s /bin/sh -c "nova-manage api_db sync" nova
  su -s /bin/sh -c "nova-manage db sync" nova
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
  if [ -n "$OS_VOL_GROUP" ] ; then
    crudini --set --verbose /etc/nova/nova.conf libvirt images_type lvm
    crudini --set --verbose /etc/nova/nova.conf libvirt images_volume_group "$OS_VOL_GROUP"
    # move VG createion earlier so that cinder can use it too...
    #vgremove -f openstack || :
    #vgcreate openstack $LVMDEV
  fi
   #COMPUTE_SERVICES="openvswitch libvirtd openstack-nova-compute"
  systemctl enable $COMPUTE_SERVICES
  systemctl start $COMPUTE_SERVICES
fi
