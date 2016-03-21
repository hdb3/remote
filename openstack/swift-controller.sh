openstack user create --domain default --password-prompt swift
openstack role add --project service --user swift admin
openstack service create --name swift object-store
openstack endpoint create --region RegionOne object-store public http://controller:8080/v1/AUTH_%\(tenant_id\)s
openstack endpoint create --region RegionOne object-store internal http://controller:8080/v1/AUTH_%\(tenant_id\)s
openstack endpoint create --region RegionOne object-store admin http://controller:8080/v1
yum -y -q install openstack-swift-proxy python-swiftclient python-keystoneclient python-keystonemiddleware memcached
curl -o /etc/swift/proxy-server.conf https://git.openstack.org/cgit/openstack/swift/plain/etc/proxy-server.conf-sample?h=stable/liberty
