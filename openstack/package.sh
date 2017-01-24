#
#yum -y install yum-plugin-priorities
#yum -y install centos-release-openstack-mitaka
#yum -y install python-ipaddress python2-colorama patch crudini ntp wireshark nmap fping
#yum -y upgrade
#PACKAGES="python-openstackclient mariadb MySQL-python"
if [[ $MY_ROLE =~ "controller" ]]
then
  PACKAGES="$PACKAGES mod_wsgi openstack-nova-api openstack-nova-cert openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler python-novaclient wget openstack-glance python-glance python-glanceclient openstack-keystone httpd memcached python-memcached rabbitmq-server openstack-neutron openstack-neutron-ml2 python-neutronclient openstack-cinder python-cinderclient python-oslo-db targetcli"
  if [ -n "$INSTALL_HORIZON" ]
  then
    PACKAGES="$PACKAGES openstack-dashboard"
  fi
fi
if [[ $MY_ROLE =~ "compute" ]]
then
  PACKAGES="$PACKAGES openstack-nova-compute sysfsutils openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch"
fi
if [[ $MY_ROLE =~ "network" ]]
then
  PACKAGES="$PACKAGES openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch"
fi
yum -y remove NetworkManager firewalld || :
yum -y repo-pkgs centos-openstack-mitaka reinstall
yum -y install $PACKAGES
