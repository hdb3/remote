source creds

#cp /usr/share/cinder/cinder-dist.conf /etc/cinder/cinder.conf
chown -R cinder:cinder /etc/cinder/cinder.conf

crudini --set --verbose /etc/cinder/cinder.conf database connection mysql+pymysql://cinder:$DBPASSWD@$CONTROLLER_IP/cinder

crudini --set --verbose /etc/cinder/cinder.conf DEFAULT rpc_backend rabbit
crudini --set --verbose /etc/cinder/cinder.conf DEFAULT my_ip $CONTROLLER_IP
crudini --set --verbose /etc/cinder/cinder.conf DEFAULT auth_strategy keystone

crudini --set --verbose /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_host $CONTROLLER_IP
crudini --set --verbose /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set --verbose /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_password $SERVICE_PWD

crudini --set --verbose /etc/cinder/cinder.conf oslo_concurrency lock_path /var/lock/cinder

crudini --set --verbose /etc/cinder/cinder.conf keystone_authtoken auth_uri http://$CONTROLLER_IP:5000
crudini --set --verbose /etc/cinder/cinder.conf keystone_authtoken auth_url http://$CONTROLLER_IP:35357
crudini --set --verbose /etc/cinder/cinder.conf keystone_authtoken auth_type password
crudini --set --verbose /etc/cinder/cinder.conf keystone_authtoken project_domain_name default
crudini --set --verbose /etc/cinder/cinder.conf keystone_authtoken user_domain_name default 
crudini --set --verbose /etc/cinder/cinder.conf keystone_authtoken project_name service
crudini --set --verbose /etc/cinder/cinder.conf keystone_authtoken username cinder
crudini --set --verbose /etc/cinder/cinder.conf keystone_authtoken password $SERVICE_PWD

crudini --set --verbose /etc/cinder/cinder.conf lvm volume_driver cinder.volume.drivers.lvm.LVMVolumeDriver
crudini --set --verbose /etc/cinder/cinder.conf lvm volume_group openstack
crudini --set --verbose /etc/cinder/cinder.conf lvm iscsi_protocol iscsi
crudini --set --verbose /etc/cinder/cinder.conf lvm iscsi_helper lioadm
crudini --set --verbose /etc/cinder/cinder.conf DEFAULT enabled_backends lvm
crudini --set --verbose /etc/cinder/cinder.conf DEFAULT glance_api_servers http://$CONTROLLER_IP:9292
crudini --set --verbose /etc/cinder/cinder.conf oslo_concurrency lock_path /var/lib/cinder/tmp

su -s /bin/sh -c "cinder-manage db sync" cinder
systemctl enable openstack-cinder-api openstack-cinder-scheduler
systemctl start openstack-cinder-api openstack-cinder-scheduler

if [[ $MY_ROLE =~ "controller" ]] ; then
  echo "running cinder node setup"

  source creds
  openstack user create --domain default --password $SERVICE_PWD cinder
  openstack role add --project service --user cinder admin
  openstack service create --name cinder volume
  openstack service create --name cinderv2 volumev2
  openstack endpoint create --region RegionOne volume public http://$CONTROLLER_IP:8776/v1/%\(tenant_id\)s
  openstack endpoint create --region RegionOne volume internal http://$CONTROLLER_IP:8776/v1/%\(tenant_id\)s
  openstack endpoint create --region RegionOne volume admin http://$CONTROLLER_IP:8776/v1/%\(tenant_id\)s
  openstack endpoint create --region RegionOne volumev2 public http://$CONTROLLER_IP:8776/v2/%\(tenant_id\)s
  openstack endpoint create --region RegionOne volumev2 internal http://$CONTROLLER_IP:8776/v2/%\(tenant_id\)s
  openstack endpoint create --region RegionOne volumev2 admin http://$CONTROLLER_IP:8776/v2/%\(tenant_id\)s

  su -s /bin/sh -c "cinder-manage db sync" cinder
fi

