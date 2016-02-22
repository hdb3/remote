# openstack

build various openstack cluster topologies, from 'all-in-one' single node to separate control/network/compute nodes with multiple instances of any role

In addition to the scripts invoked at build time, there are additional scripts which can be used to manage nested VMs once openstack is running:

+ simple.sh - this builds two VMs connected by a pure virtual network (the only way to contact these machines would be via console - VNC, etc...)

+ external.sh - a full network topology which allows exit to the outer virtual network and even the internet!
