#!/usr/bin/env python3
import socket
import random
from ipaddress import IPv6Network, IPv6Address


#Site    	Number of subnets   from                        to
#Grenoble 	128 	            2001:660:5307:3100::/64 	2001:660:5307:317f::/64
#Lille 	        128                 2001:660:4403:0480::/64 	2001:660:4403:04ff::/64
#Paris 	        128                 2001:660:330f:a280::/64 	2001:660:330f:a2ff::/64
#Saclay 	64 	            2001:660:3207:04c0::/64 	2001:660:3207:04ff::/64
#Strasbourg 	32 	            2001:660:4701:f0a0::/64 	2001:660:4701:f0bf::/64

subnets = {
    'grenoble': '2001:660:5307:3100::/57',
    'lille': '2001:660:4403:0480::/57',
    'paris': '2001:660:330f:a280::/57',
    'saclay': '2001:660:3207:04c0::/58',
    'strasbourg': '2001:660:4701:f0a0::/59'
}

hostname = socket.gethostname()

if hostname not in subnets.keys():
    print("Unknown hostname %s" % (hostname))
    exit(-1)


random.seed()
subnet = subnets[hostname]
network = IPv6Network(subnet)
random_network = IPv6Network((network.network_address + (random.getrandbits(64 - network.prefixlen) << 64 ), 64))
print(random_network)
