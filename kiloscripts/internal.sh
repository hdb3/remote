ovs-vsctl del-port br-ex eth2
ip addr add 172.16.1.1 dev br-ex
ip link set dev br-ex up
route add -net 172.16.1.0/24 gw 172.16.1.1
crudini --set --verbose /etc/sysctl.conf "" net.ipv4.ip_forward 1
sysctl -p
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
