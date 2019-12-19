#!/bin/bash
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

# name of primary network interface (before tunnel)
PRIMARY=wlan0

# address of tunnel server
SERVER=seattle.vpn.riseup.net
# address of vpn server
VPN_SERVER=seattle.vpn.riseup.net

# gateway ip address (before tunnel - adsl router ip address)
# automatically determine the ip from the default route
GATEWAY=`route -n | grep $PRIMARY | egrep "^0\.0\.0\.0" | tr -s " " | cut -d" " -f2`

# provided by pppd: interface name
TUNNEL=tun0

openvpn --config /my/path/to/riseup.ovpn --auth-user-pass /my/path/to/authentication.conf &

# iptables rules - important!

#LOCAL_NET=192.168.0.0/16
LOCAL_NET=$GATEWAY

# Flush all previous filter rules, you might not want to include this line if you already have other rules setup
iptables -t filter --flush

iptables -t filter -X MYVPN
iptables -t filter -N MYVPN

# Exceptions for local traffic & vpn server
iptables -t filter -A MYVPN -o lo -j RETURN
iptables -t filter -A MYVPN -o ${TUNNEL} -j RETURN
iptables -t filter -A MYVPN --dst 127.0.0.1 -j RETURN
iptables -t filter -A MYVPN --dst $LOCAL_NET -j RETURN
iptables -t filter -A MYVPN --dst ${SERVER} -j RETURN
iptables -t filter -A MYVPN --dst ${VPN_SERVER} -j RETURN
# Add extra local nets here as necessary

iptables -t filter -A MYVPN -j DROP

# MYVPN traffic leaving this host:
iptables -t filter -A OUTPUT -p tcp --syn -j MYVPN
iptables -t filter -A OUTPUT -p icmp -j MYVPN
iptables -t filter -A OUTPUT -p udp -j MYVPN

echo "nameserver 8.8.8.8" > /etc/resolv.conf
