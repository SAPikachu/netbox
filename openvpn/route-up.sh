#!/bin/bash

echo route-up

vars="ifconfig_local ifconfig_remote ifconfig_netmask local remote_1 route_net_gateway route_vpn_gateway route_network_1 route_netmask_1 route_gateway_1 local_net local_route_params"

for x in $vars; do
    echo $x: $(eval echo "\$$x")
done

set -u

table="table openvpn"

gateway_route=`ip route get $remote_1 | head -1 | sed s/^$remote_1//`

ip route flush $table

export OPENVPN_ROUTE_TABLE="$table"

# Copy all routes except default route to the table
ip route show | grep -v ^default | awk '{ system("ip route add " $0 "$OPENVPN_ROUTE_TABLE") } '

ip route add $remote_1/32 $gateway_route $table
ip route add default via $route_vpn_gateway $table

ip route flush cache

initctl emit --no-wait openvpn-route-up GATEWAY_ROUTE="$gateway_route" TABLE="$table"

exit 0
