#!/bin/bash
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

iptables -t filter --flush
iptables -t filter -X MYVPN
