#!/bin/sh

# This script helps to debug and understand how a host name is resolved 
# in glibc nss mechanism
# usage: nss_debug [host1] [host2] ....

keys=$*
database=ahosts
#database=hosts



for l in $(ls /usr/lib/libnss_*.so.*)
do
	filename=$(basename -- "$l")
	fname="${filename%%.*}"
	service="${fname#*_}"
	services="${services} $service"
done
echo "Found the following nss plugins (/usr/lib/libnss_*):"
echo $services


#overriding nss services
#from /etc/nsswitch.conf
services="files mymachines myhostname mdns_minimal resolve dns wins"
echo "Quering using the following methods:"
echo $services


for s in $services
do
	echo "->using ${s}"
	getent -s $s $database ${keys}
done
