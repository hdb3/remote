
source creds

#create keystone entries for glance
openstack user create --domain default --password $SERVICE_PWD glance
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image service" image

openstack endpoint create --region RegionOne image public http://$CONTROLLER_IP:9292
openstack endpoint create --region RegionOne image internal http://$CONTROLLER_IP:9292
openstack endpoint create --region RegionOne image admin http://$CONTROLLER_IP:9292

#install glance
for inifile in /etc/glance/glance-api.conf /etc/glance/glance-registry.conf
  do
    crudini --set --verbose $inifile database connection mysql+pymysql://glance:$DBPASSWD@$CONTROLLER_IP/glance
    crudini --set --verbose $inifile keystone_authtoken auth_uri http://$CONTROLLER_IP:5000
    crudini --set --verbose $inifile keystone_authtoken auth_url http://$CONTROLLER_IP:35357
    crudini --set --verbose $inifile keystone_authtoken memcached_servers $CONTROLLER_IP:11211
    crudini --set --verbose $inifile keystone_authtoken auth_type password
    crudini --set --verbose $inifile keystone_authtoken project_domain_name default
    crudini --set --verbose $inifile keystone_authtoken user_domain_name default
    crudini --set --verbose $inifile keystone_authtoken project_name service
    crudini --set --verbose $inifile keystone_authtoken username glance
    crudini --set --verbose $inifile keystone_authtoken password $SERVICE_PWD
    crudini --set --verbose $inifile paste_deploy flavor keystone

    if [ -n "$LVMDEV" && "${GLANCEUSES^^}" =~ "CINDER" ] ; then
      crudini --set --verbose $inifile glance_store stores cinder,http
      crudini --set --verbose $inifile glance_store default_store cinder
      crudini --set --verbose $inifile glance_store cinder_os_region_name default
      crudini --set --verbose $inifile glance_store cinder_api_insecure True
      crudini --set --verbose $inifile glance_store cinder_store_user_name cinder
      crudini --set --verbose $inifile glance_store cinder_store_password cinder
      crudini --set --verbose $inifile glance_store cinder_store_project_name cinder
    else
      crudini --set --verbose $inifile glance_store stores file,http
      crudini --set --verbose $inifile glance_store default_store file
      # crudini --set --verbose $inifile glance_store filesystem_store_datadir /var/lib/glance/images/
    fi
  done

#start glance
su -s /bin/sh -c "glance-manage db_sync" glance
systemctl enable openstack-glance-api openstack-glance-registry
systemctl restart openstack-glance-api openstack-glance-registry

#upload the cirros image to glance
if [ -f cirros-0.3.4-x86_64-disk.img ]
then
  echo "no need to download cirros again"
else
  export http_proxy="$WWWPROXY"
  wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
fi
# it can take a short while before glance service is available....
until openstack image list
do
  echo "retrying image list..."
done

openstack image create --public --file cirros-0.3.4-x86_64-disk.img --disk-format qcow2 --container-format bare "cirros"
