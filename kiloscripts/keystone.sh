
sed -i -e "/^#/d" /etc/keystone/keystone.conf
sed -i -e "/^$/d" /etc/keystone/keystone.conf

crudini --set --verbose /etc/keystone/keystone.conf DEFAULT admin_token $ADMIN_TOKEN
crudini --set --verbose /etc/keystone/keystone.conf database connection "mysql://keystone:$DBPASSWD@$CONTROLLER_IP/keystone"
crudini --set --verbose /etc/keystone/keystone.conf memcache servers localhost:11211
crudini --set --verbose /etc/keystone/keystone.conf token provider keystone.token.providers.uuid.Provider
crudini --set --verbose /etc/keystone/keystone.conf token driver keystone.token.persistence.backends.memcache.Token
crudini --set --verbose /etc/keystone/keystone.conf revoke driver keystone.contrib.revoke.backends.sql.Revoke
#exit
#keystone-manage pki_setup --keystone-user keystone --keystone-group keystone
#chown -R keystone:keystone /var/log/keystone
#chown -R keystone:keystone /etc/keystone/ssl
#chmod -R o-rwx /etc/keystone/ssl
su -s /bin/sh -c "keystone-manage db_sync" keystone

sed -i.bak -e "/^ServerRoot/a ServerName $CONTROLLER_IP" /etc/httpd/conf/httpd.conf

mkdir -p /var/www/cgi-bin/keystone

curl http://git.openstack.org/cgit/openstack/keystone/plain/httpd/keystone.py?h=stable/kilo | tee /var/www/cgi-bin/keystone/main /var/www/cgi-bin/keystone/admin

chown -R keystone:keystone /var/www/cgi-bin/keystone
chmod 755 /var/www/cgi-bin/keystone/*

systemctl enable openstack-keystone
systemctl start openstack-keystone

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
