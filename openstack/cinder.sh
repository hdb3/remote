source creds

#cp /usr/share/cinder/cinder-dist.conf /etc/cinder/cinder.conf
chown -R cinder:cinder /etc/cinder/cinder.conf

crudini --set --verbose /etc/cinder/cinder.conf database connection mysql://cinder:$DBPASSWD@$CONTROLLER_IP/cinder

crudini --set --verbose /etc/cinder/cinder.conf DEFAULT rpc_backend rabbit
crudini --set --verbose /etc/cinder/cinder.conf DEFAULT my_ip $CONTROLLER_IP
crudini --set --verbose /etc/cinder/cinder.conf DEFAULT auth_strategy keystone

crudini --set --verbose /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_host $CONTROLLER_IP
crudini --set --verbose /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set --verbose /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_password $SERVICE_PWD

crudini --set --verbose /etc/cinder/cinder.conf oslo_concurrency lock_path /var/lock/cinder

crudini --set --verbose /etc/cinder/cinder.conf keystone_authtoken auth_uri http://$CONTROLLER_IP:5000
crudini --set --verbose /etc/cinder/cinder.conf keystone_authtoken auth_url http://$CONTROLLER_IP:35357
crudini --set --verbose /etc/cinder/cinder.conf keystone_authtoken auth_plugin password
crudini --set --verbose /etc/cinder/cinder.conf keystone_authtoken project_domain_id default
crudini --set --verbose /etc/cinder/cinder.conf keystone_authtoken user_domain_id default 
crudini --set --verbose /etc/cinder/cinder.conf keystone_authtoken project_name service
crudini --set --verbose /etc/cinder/cinder.conf keystone_authtoken username cinder
crudini --set --verbose /etc/cinder/cinder.conf keystone_authtoken password $SERVICE_PWD
crudini --set --verbose /etc/cinder/cinder.conf keystone_authtoken

su -s /bin/sh -c "cinder-manage db sync" cinder
systemctl enable openstack-cinder-api openstack-cinder-scheduler
systemctl start openstack-cinder-api openstack-cinder-scheduler
