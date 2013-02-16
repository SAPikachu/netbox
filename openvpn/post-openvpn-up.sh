#!/bin/bash

if [ "x$script_type" == "xup" ] && [ "x$script_context" == "xinit" ]; then
    # Execute later in route-up event
    exit 0;
fi
service unbound restart
[ -f /usr/sbin/pdnsd-ctl ] && /usr/sbin/pdnsd-ctl empty-cache 2>&1
initctl restart squid3
sleep 5
ddclient
