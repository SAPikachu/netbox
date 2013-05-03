#!/bin/bash

echo route-up

vars="ifconfig_local ifconfig_remote ifconfig_netmask local remote_1 route_net_gateway route_vpn_gateway route_network_1 route_netmask_1 route_gateway_1 local_net local_route_params"

for x in $vars; do
    echo $x: $(eval echo "\$$x")
done

set -u

table="table openvpn"

gateway_route=`/etc/sapikachu/vpnutils/gateway-route.sh $remote_1`

if [ "x${script_context-init}" != "xrestart" ]; then
    # Several environment variables are missing on restart,
    # So we can't repopulate route table

    ip route flush $table

    export OPENVPN_ROUTE_TABLE="$table"

    # Copy all routes except default route to the table
    ip route show | grep -v ^default | awk '{ system("ip route add " $0 "$OPENVPN_ROUTE_TABLE") } '

    # Also add to the main table, since openvpn uses main table itself
    # Force IPv4, so that it will be ignored for IPv6 server
    ip -4 route add $remote_1/32 $gateway_route

    ip -4 route add $remote_1/32 $gateway_route $table
    ip -4 route add default via $route_vpn_gateway $table

    ip -4 route flush cache
fi

iptables -t nat -F vpn-action
iptables -t filter -F vpn-reject

initctl emit --no-wait openvpn-route-up GATEWAY_ROUTE="$gateway_route" TABLE="$table" script_type="${script_type-init}" script_context="${script_context-init}"

exit 0
