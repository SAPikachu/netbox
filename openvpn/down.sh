#!/bin/bash

echo down

interface="eth0"
if_ip=`ip addr show primary $interface | sed -n 's/ *inet \(.*\)\/.*/\1/p'`

local_net=$(echo $if_ip | cut -d. -f 1-3).0
local_route_params="dev $interface proto kernel scope link src $if_ip"

echo "$local_net / $local_route_params"

initctl stop post-openvpn-up || true

set -u

iptables -t filter -A vpn-reject -j REJECT --reject-with icmp-host-unreachable
iptables -t nat -F vpn-action

if [ "x${script_context-init}" != "xrestart" ]; then
    # Several environment variables are missing on restart,
    # So we must keep the route table in that case

    table="table openvpn"
    ip route flush $table
    ip route add $local_net/24 $local_route_params $table
    ip route add unreachable default $table

    ip route flush cache

fi

exit 0
