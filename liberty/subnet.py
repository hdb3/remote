#!/usr/bin/python

# take a subnet specification and search for a matching local interface
# don't be too pedantic - i.e. ignore the actual subnet mask on the interface

# method:
# read the subet as an IP address as the first and only parameter
# find all of the locally numbered interfaces
# match them against the subnet mask
# output the (only) one that matches
# scream if there is not exactly one match

import netifaces
from sys import exit, stderr,argv
import colorama
import ipaddress  # note - this requires the py2-ipaddress module!
from struct import unpack

def getaddrs():
    addrs = []
    for iface in netifaces.interfaces():
        ifaddresses = netifaces.ifaddresses(iface)
        if netifaces.AF_INET in ifaddresses:
            addrs.append((iface,ifaddresses[netifaces.AF_INET][0]['addr']))
    return addrs


def get_trailing_zero_bit_count(n):
    ret=0
    while 0 == n & 1:
        n = n >> 1
        ret=ret+1
    return ret

def red(s):
    print >> stderr,colorama.Fore.RED + s + colorama.Fore.RESET

def green(s):
    print >> stderr,colorama.Fore.GREEN + s + colorama.Fore.RESET

def main():
    if len(argv)<2:
        red("please give me something to work on....?")
        exit(1)
    else:
        net = ipaddress.ip_network(argv[1])
        binaddr = unpack("!I",net.network_address.packed)[0]
        if net.prefixlen == 32:
            net = ipaddress.ip_network("%s/%s" % (net.network_address,32 - get_trailing_zero_bit_count(binaddr)))
        # print net
        # red("this is RED!")
        # print "and this is not...."
    # exit(0)
    # now grab a list of lcal interface addresses and see if we match any of them to our role list from the configuratioon file

    addrs = getaddrs()
    for (iface,addr) in addrs:
        if ipaddress.ip_address(addr) in net:
           green("I found a matching interface for this subnet! (%s,%s,%s)" % (addr,iface,net.exploded))
           print "%s" % addr
           exit(0)
    red("no interface was found for the network %s" % net.exploded) 
    # exit(1)
    print "ERROR"
# end of main!

main()
