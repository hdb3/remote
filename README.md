# remote
collection of scripts and bundles for running automated installs on newly commissioned VMs

*Usage: ./remote.sh dir host1 host2 ... hostN*

where *dir* is an existing sub-directory containing at least the text file 'do_it', and every subsequent parameter is the DNS resolvable name or IP address of a target machine.  All of the files in this first-named sub-directory will be copied to each target host in turn, and then the script 'do_it' executed one each remote host, in turn.

The scripts role.py and subnet.py, and the 'roles' configuration file, if they exist in the sub-directory, may support role specific host configuration, driven by assigned IP addresses.

## user name for ssh to targets
The config directory may contain a file 'user': if it does then the contents of that file should be a string which is a valid user name for ssh access.

## Motivation
The intended first use is the automated build of OpenStack clusters, where typically a single controller nose is supported by a separate network node and one or more compute hosts.

See also the linked project 'ministack' which can be used to quickly boot networked clusters in OpenStack.  A typical scenario would first use 'ministack' to create target hosts connected by one or more virtual networks, followed by use of this 'remote' script to build the services wanted within the VMs created by 'ministack'.