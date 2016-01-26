#!/bin/bash -e
sudo ovs-vsctl del-port br-ex eth2
sudo ip addr add 172.16.1.1 dev br-ex
sudo ip link set dev br-ex up
sudo route add -net 172.16.1.0/24 gw 172.16.1.1
sudo crudini --set --verbose /etc/sysctl.conf "" net.ipv4.ip_forward 1
sudo sysctl -p
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
