#!/bin/bash

[ -f /usr/sbin/pdnsd-ctl ] && /usr/sbin/pdnsd-ctl empty-cache 2>&1
initctl restart squid3
sleep 5
ddclient
