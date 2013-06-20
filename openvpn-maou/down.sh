#!/bin/bash

initctl emit --no-wait vpn-event EVENT=vpn_down LABEL=$config

iptables -D dynamic-forward -i eth0 -o $dev -j ACCEPT
iptables -D dynamic-forward -i $dev -o eth0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -D dynamic-input -i $dev -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -t nat -D dynamic-masquerade -o $dev -j MASQUERADE

exit 0
