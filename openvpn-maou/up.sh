#!/bin/bash

iptables -I dynamic-forward -i eth0 -o $dev -j ACCEPT
iptables -I dynamic-forward -i $dev -o eth0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -I dynamic-input -i $dev -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -t nat -A dynamic-masquerade -o $dev -j MASQUERADE

initctl emit --no-wait vpn-event EVENT=vpn_up IP=$route_vpn_gateway LABEL=$config

exit 0
