
source creds

#create keystone entries for glance
openstack user create --password $SERVICE_PWD glance
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image service" image
openstack endpoint create --publicurl http://$CONTROLLER_IP:9292 --internalurl http://$CONTROLLER_IP:9292 --adminurl http://$CONTROLLER_IP:9292 --region RegionOne image

#install glance

crudini --set --verbose /etc/glance/glance-api.conf database connection mysql://glance:$DBPASSWD@$CONTROLLER_IP/glance
crudini --set --verbose /etc/glance/glance-api.conf keystone_authtoken auth_uri http://$CONTROLLER_IP:5000
crudini --set --verbose /etc/glance/glance-api.conf keystone_authtoken auth_url http://$CONTROLLER_IP:35357
crudini --set --verbose /etc/glance/glance-api.conf keystone_authtoken auth_plugin password
crudini --set --verbose /etc/glance/glance-api.conf keystone_authtoken project_domain_id default
crudini --set --verbose /etc/glance/glance-api.conf keystone_authtoken user_domain_id default
crudini --set --verbose /etc/glance/glance-api.conf keystone_authtoken project_name service
crudini --set --verbose /etc/glance/glance-api.conf keystone_authtoken username glance
crudini --set --verbose /etc/glance/glance-api.conf keystone_authtoken password $SERVICE_PWD
crudini --set --verbose /etc/glance/glance-api.conf paste_deploy flavor keystone

crudini --set --verbose /etc/glance/glance-api.conf glance_store default_store file
crudini --set --verbose /etc/glance/glance-api.conf glance_store filesystem_store_datadir /var/lib/glance/images/

crudini --set --verbose /etc/glance/glance-api.conf DEFAULT notification_driver noop
crudini --set --verbose /etc/glance/glance-api.conf DEFAULT verbose True

crudini --set --verbose /etc/glance/glance-registry.conf database connection mysql://glance:$DBPASSWD@$CONTROLLER_IP/glance
crudini --set --verbose /etc/glance/glance-registry.conf keystone_authtoken auth_uri http://$CONTROLLER_IP:5000
crudini --set --verbose /etc/glance/glance-registry.conf keystone_authtoken auth_url http://$CONTROLLER_IP:35357
crudini --set --verbose /etc/glance/glance-registry.conf keystone_authtoken auth_plugin password
crudini --set --verbose /etc/glance/glance-registry.conf keystone_authtoken project_domain_id default
crudini --set --verbose /etc/glance/glance-registry.conf keystone_authtoken user_domain_id default
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
glance image-create --name "cirros-0.3.3-x86_64" --file cirros-0.3.4-x86_64-disk.img --disk-format qcow2 --container-format bare --is-public True --progress
glance image-list
