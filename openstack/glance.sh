
source creds

#create keystone entries for glance
openstack user create --domain default --password $SERVICE_PWD glance
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image service" image

openstack endpoint create --region RegionOne image public http://$CONTROLLER_IP:9292
openstack endpoint create --region RegionOne image internal http://$CONTROLLER_IP:9292
openstack endpoint create --region RegionOne image admin http://$CONTROLLER_IP:9292
#install glance

crudini --set --verbose /etc/glance/glance-api.conf database connection mysql+pymysql://glance:$DBPASSWD@$CONTROLLER_IP/glance
crudini --set --verbose /etc/glance/glance-api.conf keystone_authtoken auth_uri http://$CONTROLLER_IP:5000
crudini --set --verbose /etc/glance/glance-api.conf keystone_authtoken auth_url http://$CONTROLLER_IP:35357
crudini --set --verbose /etc/glance/glance-api.conf keystone_authtoken memcached_servers $CONTROLLER_IP:11211
crudini --set --verbose /etc/glance/glance-api.conf keystone_authtoken auth_type password
crudini --set --verbose /etc/glance/glance-api.conf keystone_authtoken project_domain_name default
crudini --set --verbose /etc/glance/glance-api.conf keystone_authtoken user_domain_name default
crudini --set --verbose /etc/glance/glance-api.conf keystone_authtoken project_name service
crudini --set --verbose /etc/glance/glance-api.conf keystone_authtoken username glance
crudini --set --verbose /etc/glance/glance-api.conf keystone_authtoken password $SERVICE_PWD
crudini --set --verbose /etc/glance/glance-api.conf paste_deploy flavor keystone
crudini --set --verbose /etc/glance/glance-api.conf DEFAULT notification_driver noop
crudini --set --verbose /etc/glance/glance-api.conf DEFAULT verbose True

crudini --set --verbose /etc/glance/glance-api.conf glance_store stores file,http
crudini --set --verbose /etc/glance/glance-api.conf glance_store default_store file
crudini --set --verbose /etc/glance/glance-api.conf glance_store filesystem_store_datadir /var/lib/glance/images/

crudini --set --verbose /etc/glance/glance-registry.conf database connection mysql+pymsql://glance:$DBPASSWD@$CONTROLLER_IP/glance
crudini --set --verbose /etc/glance/glance-registry.conf keystone_authtoken auth_uri http://$CONTROLLER_IP:5000
crudini --set --verbose /etc/glance/glance-registry.conf keystone_authtoken auth_url http://$CONTROLLER_IP:35357
crudini --set --verbose /etc/glance/glance-registry.conf keystone_authtoken memcached_servers $CONTROLLER_IP:11211
crudini --set --verbose /etc/glance/glance-registry.conf keystone_authtoken auth_type password
crudini --set --verbose /etc/glance/glance-registry.conf keystone_authtoken project_domain_name default
crudini --set --verbose /etc/glance/glance-registry.conf keystone_authtoken user_domain_name default
crudini --set --verbose /etc/glance/glance-registry.conf keystone_authtoken project_name service
crudini --set --verbose /etc/glance/glance-registry.conf keystone_authtoken username glance
crudini --set --verbose /etc/glance/glance-registry.conf keystone_authtoken password $SERVICE_PWD
crudini --set --verbose /etc/glance/glance-registry.conf paste_deploy flavor keystone
crudini --set --verbose /etc/glance/glance-registry.conf DEFAULT notification_driver noop
crudini --set --verbose /etc/glance/glance-registry.conf DEFAULT verbose True

#start glance
su -s /bin/sh -c "glance-manage db_sync" glance
systemctl enable openstack-glance-api openstack-glance-registry
systemctl restart openstack-glance-api openstack-glance-registry

#upload the cirros image to glance
if [ -f cirros-0.3.4-x86_64-disk.img ]
then
  echo "no need to download cirros again"
else
  wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
fi
openstack image create --public --file cirros-0.3.4-x86_64-disk.img --disk-format qcow2 --container-format bare "cirros-0.3.3-x86_64"
