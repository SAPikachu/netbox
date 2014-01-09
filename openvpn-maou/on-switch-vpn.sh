#!/bin/bash

PREFIX=$(dirname $(readlink -m $0))
. $PREFIX/../conf.sh

[ -f /usr/sbin/pdnsd-ctl ] && /usr/sbin/pdnsd-ctl empty-cache 2>&1
[ -f /usr/sbin/pdnsd-ctl ] && $PREFIX/../pdnsd/update-dns.sh 2>&1
initctl restart squid3
sleep 5
ddclient
