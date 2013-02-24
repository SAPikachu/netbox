#!/bin/bash

PREFIX=$(dirname $(readlink -m $0))
. $PREFIX/../conf.sh

service unbound restart
[ -f /usr/sbin/pdnsd-ctl ] && /usr/sbin/pdnsd-ctl empty-cache 2>&1
initctl restart squid3
sleep 5
ddclient
wget -q -O - "https://ipv4.tunnelbroker.net/nic/update?username=$HE_TUNNEL_USERNAME&password=$HE_TUNNEL_PASSWORD&hostname=$HE_TUNNEL_ID"
