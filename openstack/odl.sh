if [ -z "$ODL_IP" ] ; then echo "ODL_IP not defined!" ; exit ; fi
sudo yum -y -q install git
# $REPO should be either https://github.com/openstack/networking-odl or https://github.com/flavio-fernandes/networking-odl
REPO=https://github.com/openstack/networking-odl
rm -rf networking-odl
git clone $REPO -b stable/kilo ; pushd networking-odl ; sudo python setup.py install ; popd
sudo crudini --verbose --set /etc/neutron/neutron.conf DEFAULT service_plugins networking_odl.l3.l3_odl.OpenDaylightL3RouterPlugin
pwd ; ls -l ml2_conf.ini.odl
sed -e " /ODL_IP/ s/ODL_IP/$ODL_IP/" -i.bak ml2_conf.ini.odl
crudini --verbose --set ml2_conf.ini.odl ovs local_ip $MY_IP
sudo crudini --verbose --merge /etc/neutron/plugins/ml2/ml2_conf.ini < ml2_conf.ini.odl
if [[ $MY_ROLE =~ "compute" ]] ; then
  sudo ovs-vsctl set-manager tcp:$ODL_IP:6640
fi
if [[ $MY_ROLE =~ "controller" ]] ; then
  systemctl restart neutron-server.service
fi

