curl -L  https://github.com/coreos/etcd/releases/download/v2.0.11/etcd-v2.0.11-linux-amd64.tar.gz -o etcd-v2.0.11-linux-amd64.tar.gz
tar xvf etcd-v2.0.11-linux-amd64.tar.gz
cd etcd-v2.0.11-linux-amd64
mv etcd* /usr/local/bin/
set +e
adduser -s /sbin/nologin -d /var/lib/etcd/ etcd
set +e
chmod 700 /var/lib/etcd/

if [[ $MY_ROLE =~ "controller" ]] ; then
echo "tmpfs /var/lib/etcd tmpfs nodev,nosuid,noexec,nodiratime,size=512M 0 0" >> /etc/fstab
mount -a
cat << EOF1 > /etc/sysconfig/etcd
ETCD_DATA_DIR=/var/lib/etcd
ETCD_NAME="ETCDMASTER"
ETCD_ADVERTISE_CLIENT_URLS="http://$CONTROLLER_IP:2379,http://$CONTROLLER_IP:4001"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379,http://0.0.0.0:4001"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://$CONTROLLER_IP:2380"
ETCD_INITIAL_CLUSTER="ETCDMASTER=http://$CONTROLLER_IP:2380"
ETCD_INITIAL_CLUSTER_STATE=new
EOF1
cat << 'EOF2' > /usr/local/bin/start-etcd
#!/bin/sh
export ETCD_INITIAL_CLUSTER_TOKEN=`uuidgen`
exec /usr/local/bin/etcd
EOF2
chmod +x /usr/local/bin/start-etcd
crudini --set --verbose  /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers "local, flat"
crudini --set --verbose  /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types local
crudini --set --verbose  /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers calico
crudini --set --verbose  /etc/neutron/neutron.conf DEFAULT dhcp_agents_per_network 5
yum install -y calico-control
systemctl restart neutron-server openstack-nova-api
else
cat << EOF3 > /etc/sysconfig/etcd
ETCD_PROXY=on
ETCD_DATA_DIR=/var/lib/etcd
ETCD_INITIAL_CLUSTER="ETCDMASTER=http://$CONTROLLER_IP:2380"
EOF3
crudini --set --verbose /etc/libvirt/qemu.conf "" clear_emulator_capabilities 0
crudini --set --verbose /etc/libvirt/qemu.conf "" user '"root"'
crudini --set --verbose /etc/libvirt/qemu.conf "" group '"root"'
crudini --set --verbose /etc/libvirt/qemu.conf "" cgroup_device_acl '[ "/dev/null", "/dev/full", "/dev/zero", "/dev/random", "/dev/urandom", "/dev/ptmx", "/dev/kvm", "/dev/kqemu", "/dev/rtc", "/dev/hpet", "/dev/net/tun", ]'
service libvirtd restart
crudini --del --verbose /etc/nova/nova.conf DEFAULT linuxnet_interface_driver
crudini --del --verbose /etc/nova/nova.conf neutron service_neutron_metadata_proxy
crudini --del --verbose /etc/nova/nova.conf neutron service_metadata_proxy
crudini --del --verbose /etc/nova/nova.conf neutron metadata_proxy_shared_secret
systemctl restart openstack-nova-compute
systemctl stop neutron-openvswitch-agent openvswitch
systemctl disable neutron-openvswitch-agent openvswitch
fi
cat << EOF4 > /usr/lib/systemd/system/etcd.service
[Unit]
Description=Etcd
After=syslog.target network.target

[Service]
User=root
ExecStart=/usr/local/bin/etcd
EnvironmentFile=-/etc/sysconfig/etcd
KillMode=process
Restart=always

[Install]
WantedBy=multi-user.target
EOF4
systemctl start etcd
systemctl enable etcd

if [[ $MY_ROLE =~ "controller" ]] ; then
#Then, on your control node, run the following command to find the agents that you just stopped:
#
#neutron agent-list
#For each agent, delete them with the following command on your control node, replacing <agent-id> with the ID of the agent:
#
#neutron agent-delete <agent-id>
for id in $(neutron agent-list | awk "/neutron-/ {print \$2}") ; do echo $id ; neutron agent-delete $id ; done
else
yum install -y openstack-neutron
crudini --set --verbose /etc/neutron/dhcp_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.RoutedInterfaceDriver
# Liberty...
# crudini --set /etc/neutron/dhcp_agent.ini dhcp_driver networking_calico.agent.linux.dhcp.DnsmasqRouted
# crudini --set /etc/neutron/dhcp_agent.ini interface_driver networking_calico.agent.linux.interface.RoutedInterfaceDriver
# crudini --set /etc/neutron/dhcp_agent.ini use_namespaces False
systemctl restart neutron-dhcp-agent 
systemctl enable neutron-dhcp-agent 
yum install -y openstack-nova-api
systemctl restart openstack-nova-metadata-api
systemctl enable openstack-nova-metadata-api
yum install -y bird bird6 calico-compute
calico-gen-bird-conf.sh $MY_IP $CONTROLLER_IP 65000
cp /etc/calico/felix.cfg.example /etc/calico/felix.cfg

fi
