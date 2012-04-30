#!/bin/bash

# undefined variable is error
set -u

PREFIX=$(dirname $(readlink -m $0))

SERVICE_LOCAL_IP=192.168.1.240

ip rule list | grep "openvpn" > /dev/null
if [ "$?" -ne "0" ]; then
    ip addr add $SERVICE_LOCAL_IP/24 brd + dev eth0
    ip rule add from $SERVICE_LOCAL_IP/32 table openvpn
    ip rule add from 192.168.1.32/29 table openvpn

    ip route add 192.168.1.0/24 proto kernel scope link metric 1 table openvpn

    ip route flush cache
fi

echo "1" > /proc/sys/net/ipv4/ip_forward

echo 60 > /proc/sys/net/ipv4/tcp_keepalive_time
echo 30 > /proc/sys/net/ipv4/tcp_keepalive_intvl
echo 5 > /proc/sys/net/ipv4/tcp_keepalive_probes

$PREFIX/reset-iptables.sh

# nat
iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS  --clamp-mss-to-pmtu
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.1.0/24 -j MASQUERADE
iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
iptables -t nat -A POSTROUTING -o ppp0 -j MASQUERADE

iptables -A FORWARD -i eth0 -o tun0 -j ACCEPT
iptables -A FORWARD -i eth0 -o ppp0 -j ACCEPT
iptables -A FORWARD -i tun0 -o eth0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i ppp0 -o eth0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

iptables -A FORWARD -i eth0 -o eth0 -s 192.168.1.0/24 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth0 -d 192.168.1.0/24 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# iptables -A FORWARD -m limit --limit 1/second -j LOG --log-level 7 --log-prefix "FORWARD DROP: "
iptables -A FORWARD -j DROP

# firewall

# enable loopback
iptables -A INPUT -i lo -p all -j ACCEPT
iptables -A OUTPUT -o lo -p all -j ACCEPT

#
iptables -A INPUT -i eth0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i tun0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i ppp0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport ssh -j ACCEPT
iptables -A INPUT -p tcp -s 192.168.1.0/24 --dport 3128 -j ACCEPT
iptables -A INPUT -p tcp -s 192.168.1.0/24 --dport 443 -j ACCEPT
iptables -A INPUT -p udp -s 192.168.1.0/24 --dport 53 -j ACCEPT
#iptables -A INPUT -s 192.168.1.0/24 -d $LOCAL_IP -j ACCEPT

# cfosspeed status broadcast
iptables -A INPUT -i eth0 -p udp -m addrtype --dst-type BROADCAST -m udp --sport 889 --dport 889 -j DROP

# dropbox lansync discovery
iptables -A INPUT -i eth0 -p udp -m addrtype --dst-type BROADCAST -m udp --sport 17500 --dport 17500 -j DROP

# ping from internal network
iptables -A INPUT -p icmp --icmp-type 8 -s 192.168.1.0/24 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

# iptables -A INPUT -m limit --limit 1/second -j LOG --log-level 7 --log-prefix "INPUT DROP: "
iptables -A INPUT -j DROP


# iptables -A OUTPUT -m limit --limit 1/second -j LOG --log-level 7 --log-prefix "OUTPUT: "

