#!/bin/sh

# https://wiki.archlinux.org/index.php/Internet_sharing


fromDev=$1
toDev=$2

#NAT
#sysctl net.ipv4.conf.$fromDev.forwarding=1
sysctl net.ipv4.ip_forward=1

iptables -t nat -A POSTROUTING -o $fromDev -j MASQUERADE
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $toDev -o $fromDev -j ACCEPT

