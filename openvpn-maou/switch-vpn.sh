#!/bin/bash

set -u

# Turn off reverse path validation
# Needed for policy routing for local packets
sysctl -N -a -r '\.(all|eth0|tun2[0-9]+)\.rp_filter$' | awk '{ print $1 "=0" }' | sysctl -q -w -p-

table="table openvpn"

gateway_route=`/etc/sapikachu/vpnutils/gateway-route.sh $1`

export OPENVPN_ROUTE_TABLE="$table"

# Copy all routes except default route to the table
ip route show | grep -v ^default | awk '{ system("ip route replace " $0 "$OPENVPN_ROUTE_TABLE") } '

ip -4 route replace default via $1 $table
ip -4 route replace unreachable default metric 200 $table

ip -4 route flush cache

iptables -t nat -F vpn-action
iptables -t filter -F vpn-reject

initctl emit --no-wait vpn-event EVENT=vpn_switch_complete IP=$1

exit 0
