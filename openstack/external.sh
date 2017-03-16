#!/bin/bash -ex
#
source creds
source config

# build an external network if the config gives us the relavant configuration
if [[ -n "$DNS" && -n "$NET" && -n "$GW" && -n "$EXTERNAL_PORT" ]] ; then
   echo "Building an external network on $EXTERNAL_PORT"
   neutron net-create $EXTERNAL_PORT --router:external --provider:physical_network $EXTERNAL_PORT --provider:network_type flat
   if [[ -n "$POOLSTART" && -n "$POOLEND" ]] ; then
       neutron subnet-create --name subnet-${EXTERNAL_PORT} --allocation-pool start=$POOLSTART,end=$POOLEND --dns-nameserver $DNS --disable-dhcp --gateway $GW $EXTERNAL_PORT $NET
   else
       neutron subnet-create --name subnet-${EXTERNAL_PORT} --dns-nameserver $DNS --disable-dhcp --gateway $GW $EXTERNAL_PORT $NET
   fi

   # only build the internal networks if there is a valid external network to hook into

   # a externally routed internal network which does not need floating IPs
   if [[ -n "$INTNAME" && -n "$INTNET" && -n "$EXTERNAL_PORT" ]] ; then
      echo "Building a routed internal network"
   neutron net-create $INTNAME
   neutron subnet-create --name $INTNAME --dns-nameserver $DNS $INTNAME $INTNET
   neutron router-create router-${INTNAME}
   neutron router-interface-add router-${INTNAME} ${INTNAME}
   neutron router-gateway-set --disable-snat --fixed-ip ip_address=$INTGW router-${INTNAME} $EXTERNAL_PORT
   else
      echo "Not building a routed internal network"
   fi

   # an internal network which needs floating IPs
   if [[ -n "$FLOATNAME" && -n "$FLOATNET" && -n "$EXTERNAL_PORT" ]] ; then
      echo "Building a default internal network"
       neutron net-create $FLOATNAME
       neutron subnet-create --name $FLOATNAME --dns-nameserver $DNS $FLOATNAME $FLOATNET
       neutron router-create router-${FLOATNAME}
       neutron router-interface-add router-${FLOATNAME} ${FLOATNAME}
       neutron router-gateway-set router-${FLOATNAME} $EXTERNAL_PORT
   else
      echo "Not building a default internal network"
   fi

else
   echo "Not building an external network"
fi
