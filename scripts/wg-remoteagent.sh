#!/usr/bin/env bash

# Copyright (C) 2017 andreas.schmidt@thingforward.io
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#


_MODPROBE="/sbin/modprobe"
_LSMOD="/sbin/lsmod"
_IP="/sbin/ip"
_WG=$(which wg)
_JQ=$(which jq)
_SUDO=$(which sudo)

# only log to stderr if $DEBUG is set; be quite otherwise
function log() {
	[[ ! -z "$DEBUG" ]] && echo $* >/dev/stderr
}

# check for kernel module and wg binary in PATH
function is_wireguard_ready() {
	$_SUDO $_MODPROBE wireguard || {
		log "is_wireguard_ready> ERROR Unable to load wg kernel module"
	}
	$_LSMOD | grep -wq wireguard
	if [[ $? -eq 0 ]]; then
		which wg >/dev/null 2>&1
		return $?
	fi
	return 99
}

function install_wireguard_pre {
	PRE_STEP=0

	LSBR=$(which lsb_release 2>/dev/null)
	if [[ $? -eq 0 ]]; then
		LSBR_OUT=$($LSBR -a)
		if [[ "$LSBR_OUT" =~ Debian ]]; then
			log On debian.
			install_wireguard_pre_debian && {
				log "install_wireguard> installed tool chain for Debian Linux"
				return 	1
			}
		fi
	fi

	if [[ -f /etc/os-release ]]; then
		grep -wq -E 'NAME=.*Amazon Linux.*' /etc/os-release
		if [[ $? -eq 0 ]]; then
			install_wireguard_pre_amz && {
				log "install_wireguard> installed tool chain for AMZ linux"
				return 1
			}
		fi
	fi
	if [[ -f /etc/redhat-release ]]; then
		grep -wq -E 'Fedora' /etc/redhat-release
		if [[ $? -eq 0 ]]; then
			install_wireguard_pre_fc && {
				log "install_wireguard> installed tool chain for Fedora Core"
				return 1
			}
		fi
	fi

	return $PRE_STEP
}

function install_wireguard_pre_amz {
	$_SUDO yum install -y -q libmnl-devel kernel-devel @"Development tools" /usr/bin/pkg-config wget jq
	return $?
}
function install_wireguard_pre_fc {
	$_SUDO yum install -y -q libmnl-devel kernel-devel elfutils-libelf-devel @"Development tools" /usr/bin/pkg-config wget jq
	return $?
}
function install_wireguard_pre_debian {
	$_SUDO apt-get update -y -q
	$_SUDO apt-get install -y -q libmnl-dev linux-headers-$(uname -r) build-essential pkg-config wget jq
	return $?
}

function install_wireguard {
	install_wireguard_pre

	if [[ "$?" -eq 1 ]]; then
		INSTALLDIR=$(mktemp -d) &&  {
			log "install_wireguard> installing wireguard from source, in $INSTALLDIR"
			NAME=WireGuard-0.0.20170706
			FNAME=${NAME}.tar.xz
			( cd $INSTALLDIR; wget https://git.zx2c4.com/WireGuard/snapshot/${FNAME} && tar xf ${FNAME} && rm ${FNAME})

			( cd $INSTALLDIR/${NAME}/src && make && $_SUDO make install )

			rm -r $INSTALLDIR
		}

		$_MODPROBE wireguard >/dev/null 2>&1
	fi

	return 0
}

function init_wireguard_keys() {
	if [[ -z "$1" ]]; then
		log "init_wireguard_keys> ERROR Need to supply network name to create keys for it."
		return
	fi

	NETWORK_NAME="$1"
	$_SUDO su - -c 'test -d ~/.wg-ra'
	if [[ $? -eq 1 ]]; then
		$_SUDO su - -c 'mkdir ~/.wg-ra'
	fi

	$_SUDO su - -c "test -f ~/.wg-ra/${NETWORK_NAME}.privatekey"
	if [[ $? -eq 1 ]]; then
		$_SUDO su - -c "umask 077 && wg genkey >~/.wg-ra/${NETWORK_NAME}.privatekey"
		$_SUDO su - -c "test -f ~/.wg-ra/${NETWORK_NAME}.publickey"
		if [[ $? -eq 1 ]]; then
			$_SUDO su - -c "umask 077 && wg pubkey <~/.wg-ra/${NETWORK_NAME}.privatekey >~/.wg-ra/${NETWORK_NAME}.publickey"
			return 0
		fi
	fi
	$_SUDO su - -c "test -f ~/.wg-ra/${NETWORK_NAME}.publickey -a -f ~/.wg-ra/${NETWORK_NAME}.privatekey"
	return $?
}

function delete_wireguard_keys() {
	if [[ -z "$1" ]]; then
		log "ERROR Need to supply network name to delete keys for it."
		return
	fi

	NETWORK_NAME="$1"

	$_SUDO su - -c "test -f ~/.wg-ra/${NETWORK_NAME}.privatekey && rm ~/.wg-ra/${NETWORK_NAME}.privatekey"
	$_SUDO su - -c "test -f ~/.wg-ra/${NETWORK_NAME}.publickey && rm ~/.wg-ra/${NETWORK_NAME}.publickey"
}

function init_wireguard_interface() {
	if [[ -z "$1" ]]; then
		log "init_wireguard_interface> ERROR Need to supply network name to configure network interface"
		return 14
	fi

	NETWORK_NAME="$1"
	INTF="wg.${NETWORK_NAME}"

	$_IP link show "${INTF}" >/dev/null 2>&1
	if [[ $? -eq 1 ]]; then
		# create interface
		$_SUDO $_IP link add "${INTF}" type wireguard
	fi
	$_IP link show "${INTF}" >/dev/null 2>&1
}

function init_wireguard_set() {
	if [[ -z "$1" ]]; then
		log "init_wireguard_set> ERROR Need to supply network name to create keys for it."
		return 15
	fi

	NETWORK_NAME="$1"
	INTF="wg.${NETWORK_NAME}"

	if [[ -z "$2" ]]; then
		log "init_wireguard_set> ERROR Need to supply listen port"
		return 16
	fi
	LP="$2"
	$_SUDO su - -c "wg set \"${INTF}\" listen-port \"${LP}\" private-key ~/.wg-ra/${NETWORK_NAME}.privatekey"
	if [[ $? -ne 0 ]]; then
		return 20
	fi

	if [[ -z "$3" ]]; then
		log "init_wireguard_set> ERROR Need to supply internal ip"
		return
	fi
	$_SUDO su - -c "$_IP addr show dev \"${INTF}\" | grep -wq \"$3\" >/dev/null 2>&1"
	if [[ $? -ne 0 ]]; then
		$_SUDO su - -c "$_IP addr add "$3" dev ${INTF}"
		if [[ $? -ne 0 ]]; then
			return 21
		fi
	else
		log "init_wireguard_set> addr already present"
	fi

	$_SUDO $_IP link set dev "${INTF}" up

	return 0
}

function init_wireguard() {
	JSONIN=$(cat -)
	NETWORK_NAME=$(echo $JSONIN | jq -e '."network-name"' 2>/dev/null)
	if [[ $? -eq 0 ]]; then
		NETWORK_NAME=$(echo $NETWORK_NAME | tr -d '"')
		log "init_wireguard> for network \"$NETWORK_NAME\""

		init_wireguard_keys "${NETWORK_NAME}"
		if [[ $? -eq 0 ]]; then
			log "init_wireguard> keys present"

			init_wireguard_interface "${NETWORK_NAME}"
			if [[ $? -eq 0 ]]; then
                        	log "init_wireguard> interface present"
			else
				log "init_wireguard> ERROR creating interface"
				echo "{ \"network-name\": \"${NETWORK_NAME}\", \"state\": \"ERROR\", \"err\": 10 }"
				return 31
			fi
		else
			log "init_wireguard> ERROR creating keys"
			echo "{ \"network-name\": \"${NETWORK_NAME}\", \"state\": \"ERROR\", \"err\": 11 }"
			return 32
		fi
	else
		log "init_wireguard> ERROR in json input. please specifiy a network-name"
		echo "{ \"network-name\": \"${NETWORK_NAME}\", \"state\": \"ERROR\", \"err\": 12 }"
		return 33
	fi

	LISTEN_PORT=$(echo $JSONIN | jq -e '."listen-port"' 2>/dev/null)
	if [[ $? -eq 0 ]]; then
		log "init_wireguard> setting listen-port \"$LISTEN_PORT\""
	fi
	INTERNAL_IP=$(echo $JSONIN | jq -e '."ip"' 2>/dev/null)
	if [[ $? -eq 0 ]]; then
		INTERNAL_IP=$(echo ${INTERNAL_IP} | tr -d '"')
		log "init_wireguard> setting internal ip \"$INTERNAL_IP\""
	fi

	init_wireguard_set ${NETWORK_NAME} ${LISTEN_PORT} ${INTERNAL_IP}
	INIT_STATE=$?
	if [[ $INIT_STATE -ne 0 ]]; then
		echo "{ \"network-name\": \"${NETWORK_NAME}\", \"state\": \"ERROR\", \"err\": $INIT_STATE }"
	else
		# dump public key
		PUBKEY=$($_SUDO su - -c "cat ~/.wg-ra/${NETWORK_NAME}.publickey")
		echo "{ \"network-name\": \"${NETWORK_NAME}\", \"public-key\": \"${PUBKEY}\" }"
	fi
}

function delete_wireguard_interface() {
	if [[ -z "$1" ]]; then
		log "ERROR Need to supply network name to take down interface"
		return
	fi

	NETWORK_NAME="$1"
	INTF="wg.${NETWORK_NAME}"

	$_SUDO $_IP link show "${INTF}" >/dev/null 2>&1
	if [[ $? -ne 0 ]]; then
		# link does not exist anyway.
		return 0
	fi

	$_SUDO $_IP link set ${INTF} down >/dev/null 2>&1
	$_SUDO $_IP link delete dev ${INTF} >/dev/null 2>&1
	return $?
}


# takes down a wireguard interface and its configuration
function delete_wireguard() {
	JSONIN=$(cat -)
	NETWORK_NAME=$(echo $JSONIN | jq -e '."network-name"' 2>/dev/null)
	if [[ $? -eq 0 ]]; then
		NETWORK_NAME=$(echo $NETWORK_NAME | tr -d '"')
		log "delete_wireguard> for network \"$NETWORK_NAME\""

		delete_wireguard_interface "${NETWORK_NAME}"
		if [[ $? -eq 0 ]]; then
			echo "{ \"network-name\": \"${NETWORK_NAME}\", \"state\": \"DELETED\", \"err\": 0 }"

			WITHKEYS=$(echo $JSONIN | jq -e '."with-keys"' 2>/dev/null)
			if [[ "$WITHKEYS" == "true" ]]; then
				delete_wireguard_keys "${NETWORK_NAME}"
			fi
		else
			echo "{ \"network-name\": \"${NETWORK_NAME}\", \"state\": \"ERROR\", \"err\": 31 }"
		fi

	else
		log "delete_wireguard> ERROR in json input. please specifiy a network-name"
		echo "{ \"network-name\": \"${NETWORK_NAME}\", \"state\": \"ERROR\", \"err\": 12 }"
	fi

}

function removepeer0() {
	NETWORK_NAME="$1"
	INTF="wg.${NETWORK_NAME}"
	PEER="$2"

	$_SUDO wg set "${INTF}" peer "${PEER}" remove
	return $?
}

function removepeer() {
	JSONIN=$(cat -)
	NETWORK_NAME=$(echo $JSONIN | jq -e '."network-name"' 2>/dev/null)
	if [[ $? -ne 0 ]]; then
		log ERROR in json input. please specifiy a network-name
		echo "{ \"state\": \"ERROR\", \"err\": 41 }"
	fi
	PEER_PUBKEY=$(echo $JSONIN | jq -e '."peer"' 2>/dev/null)
	if [[ $? -ne 0 ]]; then
		log ERROR in json input. please specifiy a public key with peer
		echo "{ \"state\": \"ERROR\", \"err\": 42 }"
	fi
	NETWORK_NAME=$(echo $NETWORK_NAME | tr -d '"')
	PEER_PUBKEY=$(echo $PEER_PUBKEY | tr -d '"')

	OUT=$(removepeer0 $NETWORK_NAME $PEER_PUBKEY 2>&1) && {
		echo "{ \"peer\": \"$PEER_PUBKEY\", \"state\": \"ADDED\", \"err\": 0 }"
	} || {
		echo "{ \"peer\": \"$PEER_PUBKEY\", \"state\": \"ERROR\", \"err\": 49, \"message\": \"${OUT}\" }"
	}
}

function addpeer0() {
	NETWORK_NAME="$1"
	INTF="wg.${NETWORK_NAME}"
	PEER="$2"
	EP="$3"
	IP="$4"

	$_SUDO wg set "${INTF}" peer "${PEER}" endpoint "${EP}" allowed-ips "${IP}"
	if [[ $? -eq 0 ]]; then
		$_SUDO su - -c "$_IP ro add ${IP} dev ${INTF}"
		return $?
	else
		return $?
	fi
}

function addpeer() {
	JSONIN=$(cat -)
	NETWORK_NAME=$(echo $JSONIN | jq -e '."network-name"' 2>/dev/null)
	if [[ $? -ne 0 ]]; then
		log ERROR in json input. please specifiy a network-name
		echo "{ \"state\": \"ERROR\", \"err\": 41 }"
	fi
	PEER_PUBKEY=$(echo $JSONIN | jq -e '."peer"' 2>/dev/null)
	if [[ $? -ne 0 ]]; then
		log ERROR in json input. please specifiy a public key with peer
		echo "{ \"state\": \"ERROR\", \"err\": 42 }"
	fi
	PEER_EP=$(echo $JSONIN | jq -e '."endpoint"' 2>/dev/null)
	if [[ $? -ne 0 ]]; then
		log ERROR in json input. please specifiy an endpoint
		echo "{ \"state\": \"ERROR\", \"err\": 43 }"
	fi
	PEER_IP=$(echo $JSONIN | jq -e '."ip"' 2>/dev/null)
	if [[ $? -ne 0 ]]; then
		log ERROR in json input. please specifiy the internal ip
		echo "{ \"state\": \"ERROR\", \"err\": 44 }"
	fi
	NETWORK_NAME=$(echo $NETWORK_NAME | tr -d '"')
	PEER_PUBKEY=$(echo $PEER_PUBKEY | tr -d '"')
	PEER_EP=$(echo $PEER_EP | tr -d '"')
	PEER_IP=$(echo $PEER_IP | tr -d '"')

	OUT=$(addpeer0 $NETWORK_NAME $PEER_PUBKEY $PEER_EP $PEER_IP 2>&1) && {
		echo "{ \"peer\": \"$PEER_PUBKEY\", \"state\": \"ADDED\", \"err\": 0 }"
	} || {
		echo "{ \"peer\": \"$PEER_PUBKEY\", \"state\": \"ERROR\", \"err\": 49, \"message\": \"${OUT}\" }"
	}
}

## main

function usage() {
	echo 'Usage: wg-remoteagent.sh [bootstrap] [init] [delete] [peer] [unpeer]'
}



if [[ $# -eq 0 ]]; then
	usage
	exit 1
fi

if [[ ! -x "$_SUDO" ]]; then
	echo ERROR sudo needs to be installed.
	exit 1
fi


if [[ "$1" == "bootstrap" ]]; then

	is_wireguard_ready && {
		echo "wireguard is ready."
	} || {
		echo "wireguard is not ready, trying to install."
		install_wireguard
	}
elif [[ "$1" == "init" ]]; then
	init_wireguard
elif [[ "$1" == "delete" ]]; then
	delete_wireguard
elif [[ "$1" == "peer" ]]; then
	addpeer
elif [[ "$1" == "unpeer" ]]; then
	removepeer
else
	echo ERROR Unknown command.
	usage
	exit 1
fi