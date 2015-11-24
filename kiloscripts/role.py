#!/usr/bin/python

import netifaces
from sys import exit, stderr
import colorama
from pprint import pprint
from traceback import print_exc
from collections import defaultdict,OrderedDict

def getifaces():
    ifaces = [] # list of (<interface name>,<IPv4 address>)
    for iface in netifaces.interfaces():
        if iface == "lo":
            continue
        ifaddresses = netifaces.ifaddresses(iface)
        if netifaces.AF_INET in ifaddresses:
            ifaces.append((iface,ifaddresses[netifaces.AF_INET][0]['addr']))
    return ifaces

def getroles():
    try:
        infile = open("roles","r")
    except:
        print >> stderr, cfr + \
                           "Hmmm, I had a teensy problem trying to find your role configuration file:" + \
                           " is there a file somewhere here called 'roles'?"
        exit(1)

    roles = defaultdict(OrderedDict)
    addrs = defaultdict(set)

    for line in infile.readlines():
    # file format is <address> <name>
        # ignore comment lines
        if line[0] != '#':
            words = line.split()
            # ignore short lines
            if len(words) > 1:
                address = words[0]
                role = words[1]
                roles[role][address] = ()
                addrs[address].add(role)
    return (addrs,roles)

# first process the roles without considering local roles issues

def main():
    envstrings = []
    roleaddrs,roles = getroles()
    if not roleaddrs:
        return(None)

    print >> stderr, cfg + "the following roles were found:"
    for _role, _addrs in roles.iteritems():
        print >> stderr, cfg, "role %s: " % _role,
        print >> stderr, cfg , list(_addrs)

    if 'controller' not in roles:
        print >> stderr, cfr + "Warning! - no controller was found - cannot set controller IP"
    else:
        controller_ip = next(iter(roles['controller']))
        # controller_ip = roles['controller'][0]
        envstrings.append(("CONTROLLER_IP",controller_ip))
        if len(roles['controller']) > 1:
            print >> stderr, \
                cfy + \
                "Warning! - more than one controller was found -" + \
                " using first candidate for controller IP (%s)" % controller_ip

    if 'compute' not in roles:
        print >> stderr, cfy + "Warning! - no compute nodes found"

    if 'network' not in roles:
        print >> stderr, cfy + "Warning! - no network nodes found"


    # now grab a list of local interface addresses and see if we match any of them to our role list from the configuration file

    ifaces = getifaces()

    print >> stderr, cfg + "the following local interfaces were found:"
    for (iface,addr) in ifaces:
        print >> stderr, cfg , "%s:%s" % (iface,addr)

    my_roles = set()
    my_addrs = set()
    config_addrs = set()

    for (iface,addr) in ifaces:
        config_addrs.add(addr)
        if addr in roleaddrs:
            my_roles = my_roles | roleaddrs[addr]
            my_addrs.add(addr)

    if len(my_roles) == 0:
        print >> stderr, cfr + "Error - no role was found based on local addresses for this host"
        print >> stderr, "The following local interface addresses were found",
        print >> stderr, list(config_addrs)
        print >> stderr, "The following configuration role addresses were found",
        print >> stderr, list(roleaddrs)
        return(None)
    elif len(my_addrs) > 1:
        print >> stderr, cfr + "Error - multiple functional interfaces found for this host"
        return(None)
    else:
        envstrings.append(("OPENSTACK_INSTALL","yes"))

        my_addr = my_addrs.pop()
        envstrings.append(("MY_IP",my_addr))
        for (iface,addr) in ifaces:
            if addr == my_addr:
                my_iface = iface
                break

        if len(my_roles) == 1:
            my_role = my_roles.pop()
            # my_addr = list(roles[my_role])[0]
            print >> stderr, cfg + "Happy days! - a role was found based on local addresses for this host - role found: %s (address %s on interface %s)" % (my_role,my_addr,my_iface)
            envstrings.append(("MY_ROLE",my_role))
        else:
            print >> stderr, cfy + "Warning - multiple roles found based on local addresses for this host",
            print >> stderr, cfy + "roles found: %s (address %s on interface %s)" \
                                    % (list(my_roles),my_addr,my_iface)
            envstrings.append(("MY_ROLE",(",").join(list(my_roles))))
    return envstrings
# end of main!


cfr = colorama.Fore.RED
cfg = colorama.Fore.GREEN
cfy = colorama.Fore.YELLOW
colorama.init()

try:
    envstrings = main()
except:
    print >> stderr,colorama.Fore.RESET
    colorama.deinit()
    print_exc()
else:
    print >> stderr,colorama.Fore.RESET
    # print colorama.Fore.RESET
    colorama.deinit()
    if envstrings:
        for envval in envstrings:
            print "export %s=%s"  % (envval)
    else:
        exit(1)
