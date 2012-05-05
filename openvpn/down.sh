#!/bin/bash

echo down

interface="eth0"
if_ip=`ip addr show primary $interface | sed -n 's/ *inet \(.*\)\/.*/\1/p'`

local_net=$(echo $if_ip | cut -d. -f 1-3).0
local_route_params="dev $interface proto kernel scope link src $if_ip"

echo "$local_net / $local_route_params"

set -u

table="table openvpn"

ip route flush $table
ip route add $local_net/24 $local_route_params $table

ip route flush cache

exit 0
