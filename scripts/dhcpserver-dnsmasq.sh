#!/bin/sh



dev=$1

# ip link set up dev $dev
# ip addr add 192.168.20.10/24 dev $dev


systemctl restart systemd-networkd


# -d, --no-daemon 	Do NOT fork into the background: run in debug mode. 
# -k forefround
# -F dhcp range
#-z, --bind-interfaces Bind only to interfaces in use.                                                                                          
# -9, --leasefile-ro	Do not use leasfile.                                                                   

dnsmasq -i $dev -F 192.168.20.50,192.168.20.99,12h -k

#less /var/lib/misc/dnsmasq.leases


