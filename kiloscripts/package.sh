
yum -y -q install yum-plugin-priorities
yum -y -q install epel-release http://rdo.fedorapeople.org/openstack-kilo/rdo-release-kilo.rpm || echo "yum install: nothing to do"
yum -y -q upgrade
PACKAGES="patch crudini mod_wsgi python-openstackclient rabbitmq mariadb MySQL-python ntp"
if [[ $MY_ROLE =~ "controller" ]] ; then
  PACKAGES="$PACKAGES openstack-nova-api openstack-nova-cert openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler python-novaclient wget openstack-glance python-glance python-glanceclient openstack-keystone httpd memcached python-memcached rabbitmq-server mariadb-server openstack-neutron openstack-neutron-ml2 python-neutronclient openstack-dashboard openstack-cinder python-cinderclient python-oslo-db"
if [ -z "$INSTALL_HORIZON" ]; then PACKAGES="$PACKAGES openstack-dashboard" ; fi
fi
if [[ $MY_ROLE =~ "compute" ]] ; then
  PACKAGES="$PACKAGES openstack-nova-compute sysfsutils openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch"
fi
if [[ $MY_ROLE =~ "network" ]] ; then
  PACKAGES="$PACKAGES openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch"
fi
yum -y -q install $PACKAGES
