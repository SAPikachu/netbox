#!/bin/bash

echo route-up

local_net=$(echo $route_net_gateway | cut -d. -f 1-3).0
local_route_params=$(ip route get $route_net_gateway | head -1 | grep -Eo " .*")
local_route_params="$local_route_params proto kernel scope link"

vars="ifconfig_local ifconfig_remote ifconfig_netmask local remote_1 route_net_gateway route_vpn_gateway route_network_1 route_netmask_1 route_gateway_1 local_net local_route_params"

for x in $vars; do
    echo $x: $(eval echo "\$$x")
done


set -eu

table="table openvpn"

if [ "x$table" != "x" ]; then
    ip route flush $table
    ip route add $local_net/24 $local_route_params $table
fi
ip route add $remote_1/32 via $route_net_gateway $table
ip route add default via $route_vpn_gateway $table
/etc/sapikachu/openvpn/chnroutes.sh "via $route_net_gateway $table"

ip route flush cache
service unbound restart

