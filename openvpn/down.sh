#!/bin/bash

echo down

local_net=$(echo $route_net_gateway | cut -d. -f 1-3).0
local_route_params=$(ip route get $route_net_gateway | head -1 | grep -Eo " .*")
local_route_params="$local_route_params proto kernel scope link"

echo "$local_net / $local_route_params"

set -eu

table="table openvpn"

ip route flush $table
ip route add $local_net/24 $local_route_params $table
ip route add default via $route_net_gateway $table

ip route flush cache

