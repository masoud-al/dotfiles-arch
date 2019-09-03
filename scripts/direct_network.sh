#!/bin/env sh
addr=192.168.20.10/24
dev=enp0s25

ip address add $addr broadcast + dev $dev
ip link set dev $dev up


dnsmasq -i enp0s25 -F 192.168.20.50,192.168.20.99,12h -d

