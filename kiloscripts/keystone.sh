
crudini --set --verbose /etc/keystone/keystone.conf DEFAULT admin_token $ADMIN_TOKEN
crudini --set --verbose /etc/keystone/keystone.conf database connection "mysql://keystone:$DBPASSWD@$CONTROLLER_IP/keystone"
crudini --set --verbose /etc/keystone/keystone.conf memcache servers localhost:11211
crudini --set --verbose /etc/keystone/keystone.conf token provider uuid
crudini --set --verbose /etc/keystone/keystone.conf token driver memcache
crudini --set --verbose /etc/keystone/keystone.conf revoke driver sql
su -s /bin/sh -c "keystone-manage db_sync" keystone

sed -i.bak -e "/^ServerRoot/a ServerName $CONTROLLER_IP" /etc/httpd/conf/httpd.conf

cp  wsgi-keystone.conf /etc/httpd/conf.d/wsgi-keystone.conf

systemctl enable httpd memcached
systemctl restart httpd memcached

#create users and tenants
export OS_TOKEN=$ADMIN_TOKEN
export OS_URL=http://$CONTROLLER_IP:35357/v2.0

openstack service create --name keystone --description "OpenStack Identity" identity
openstack project create --description "Admin Project" admin
openstack user create --password $ADMIN_PWD admin
openstack role create admin
openstack role add --project admin --user admin admin
openstack project create --description "Service Project" service
openstack endpoint create --publicurl http://$CONTROLLER_IP:5000/v2.0 --internalurl http://$CONTROLLER_IP:5000/v2.0 --adminurl http://$CONTROLLER_IP:35357/v2.0 --region RegionOne identity
unset OS_TOKEN OS_URL

#create credentials file
echo "export OS_PROJECT_DOMAIN_ID=default" >> creds
echo "export OS_USER_DOMAIN_ID=default" >> creds
echo "export OS_PROJECT_NAME=admin" >> creds
echo "export OS_TENANT_NAME=admin" >> creds
echo "export OS_USERNAME=admin" >> creds
echo "export OS_PASSWORD=$ADMIN_PWD" >> creds
echo "export OS_AUTH_URL=http://$CONTROLLER_IP:35357/v3" >> creds
