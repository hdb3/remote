#!/bin/bash -ex
#
source creds
source config
#INTNET=10.30.64.0/24 INTNAME=net64 INTGW=10.30.65.12
#DNS=10.30.65.200 GW=10.30.65.1 NET=10.30.65.0/24
neutron net-create $EXTERNAL_PORT --router:external --provider:physical_network $EXTERNAL_PORT --provider:network_type flat
neutron subnet-create --name subnet-${EXTERNAL_PORT} --dns-nameserver $DNS --disable-dhcp --gateway $GW $EXTERNAL_PORT $NET
neutron net-create $INTNAME
neutron subnet-create --name $INTNAME $INTNAME $INTNET
neutron router-create router-${EXTERNAL_PORT}
neutron router-interface-add router-${EXTERNAL_PORT} ${INTNAME}
neutron router-gateway-set --disable-snat --fixed-ip ip_address=$INTGW router-${EXTERNAL_PORT} $EXTERNAL_PORT
