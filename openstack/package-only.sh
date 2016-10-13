yum -y install yum-plugin-priorities
yum -y install centos-release-openstack-mitaka
yum -y upgrade
yum -y install python-ipaddress python2-colorama patch crudini mod_wsgi python-openstackclient mariadb MySQL-python ntp openstack-nova-api openstack-nova-cert openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler python-novaclient wget openstack-glance python-glance python-glanceclient openstack-keystone httpd memcached python-memcached rabbitmq-server openstack-neutron openstack-neutron-ml2 python-neutronclient openstack-dashboard openstack-cinder python-cinderclient python-oslo-db openstack-dashboard openstack-nova-compute sysfsutils openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch wireshark nmap
