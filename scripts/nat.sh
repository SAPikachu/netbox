#!/bin/bash

# undefined variable is error
set -u

PREFIX=$(dirname $(readlink -m $0))
. $PREFIX/../conf.sh

ip rule list | grep "openvpn" > /dev/null
if [ "$?" -ne "0" ]; then
    ip addr add $SERVICE_IP/24 brd + dev eth0
    ip rule add fwmark 0x100/0x100 table openvpn

    ip route add 192.168.1.0/24 proto kernel scope link metric 1 table openvpn

    ip route flush cache
fi

if [ -z "$(ip tunnel show he-ipv6)" ]; then
    IPV6_MODE="add"
else
    IPV6_MODE="change"
fi

ip tunnel $IPV6_MODE he-ipv6 mode sit remote $HE_TUNNEL_SERVER_V4 local $GENERAL_IP ttl 255
ip link set he-ipv6 up
ip addr flush dev he-ipv6
ip addr add  $HE_TUNNEL_CLIENT dev he-ipv6
ip route replace ::/0 dev he-ipv6
ip -6 addr flush dev eth0 scope global
ip -6 addr add $HE_TUNNEL_IF_ADDR dev eth0

echo "1" > /proc/sys/net/ipv4/ip_forward
echo "1" > /proc/sys/net/ipv6/conf/all/forwarding

echo 60 > /proc/sys/net/ipv4/tcp_keepalive_time
echo 30 > /proc/sys/net/ipv4/tcp_keepalive_intvl
echo 5 > /proc/sys/net/ipv4/tcp_keepalive_probes

sysctl -q -w net.netfilter.nf_conntrack_acct=1

# Turn off reverse path validation
# Needed for policy routing for local packets
sysctl -q -w net.ipv4.conf.all.rp_filter=0
sysctl -q -w net.ipv4.conf.default.rp_filter=0
sysctl -q -w net.ipv4.conf.eth0.rp_filter=0 >/dev/null 2>/dev/null || true
sysctl -q -w net.ipv4.conf.tun0.rp_filter=0 >/dev/null 2>/dev/null || true

$PREFIX/reset-iptables.sh

# Create empty set here for referencing in iptables, 
# fill it at the end of script
$PREFIX/../vpnutils/ipset-chn-networks.sh --empty-set-only

iptables -t nat -N vpn-mark
iptables -t mangle -N vpn-mark-local # Must be in mangle table to affect routing
iptables -t nat -N vpn-action
iptables -t filter -N vpn-reject

ipset create vpnclients hash:net
ipset add vpnclients $SERVICE_IP
ipset add vpnclients 192.168.1.32/28
ipset add vpnclients 192.168.1.208/28
ipset add vpnclients 172.25.0.0/16

function build_mark_chain {
    # Only check each connection once
    iptables -t $1 -A $2 -j CONNMARK --restore-mark
    iptables -t $1 -A $2 -m connmark --mark 0x80/0x80 -j RETURN
    iptables -t $1 -A $2 -j CONNMARK --set-mark 0x80/0x80 

    # Only specified sources can go through VPN
    iptables -t $1 -A $2 -m set ! --match-set vpnclients src -j RETURN

    # Local packets shouldn't go through VPN
    iptables -t $1 -A $2 -i lo -j RETURN
    iptables -t $1 -A $2 -o lo -j RETURN
    iptables -t $1 -A $2 -d 10.0.0.0/8 -j RETURN
    iptables -t $1 -A $2 -d 169.254.0.0/16 -j RETURN
    iptables -t $1 -A $2 -d 172.16.0.0/12 -j RETURN
    iptables -t $1 -A $2 -d 192.168.0.0/16 -j RETURN

    # chnroutes
    iptables -t $1 -A $2 -m set --match-set chnnetworks dst -j RETURN

    # This connection should go through VPN
    iptables -t $1 -A $2 -j CONNMARK --set-mark 0x100/0x100
    iptables -t $1 -A $2 -j MARK --set-mark 0x100/0x100
}

build_mark_chain nat vpn-mark
build_mark_chain mangle vpn-mark-local

# When VPN is not connected, reject all connections to prevent information leak
iptables -t filter -A vpn-reject -j REJECT --reject-with icmp-host-unreachable

# Install custom chains
iptables -t nat -A PREROUTING -j vpn-mark
iptables -t mangle -A OUTPUT -j vpn-mark-local
iptables -t nat -A POSTROUTING -m connmark --mark 0x100/0x100 -j vpn-action
iptables -t filter -A FORWARD -m connmark --mark 0x100/0x100 -j vpn-reject
iptables -t filter -A OUTPUT -m connmark --mark 0x100/0x100 -j vpn-reject
iptables -t mangle -A PREROUTING -j CONNMARK --restore-mark
iptables -t mangle -A OUTPUT -j CONNMARK --restore-mark

# nat
iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS  --clamp-mss-to-pmtu
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.1.0/24 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 172.25.0.0/16 -j MASQUERADE
iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
iptables -t nat -A POSTROUTING -o ppp0 -j MASQUERADE

iptables -A FORWARD -i eth0 -o tun0 -j ACCEPT
iptables -A FORWARD -i eth0 -o ppp0 -j ACCEPT
iptables -A FORWARD -i tun10 -j ACCEPT
iptables -A FORWARD -i tun0 -o eth0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i ppp0 -o eth0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -o tun10 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

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
iptables -A INPUT -p udp -s 172.25.0.0/16 --dport 53 -j ACCEPT
iptables -A INPUT -p udp -s 192.168.1.0/24 --dport 137 -j ACCEPT
iptables -A INPUT -p udp --dport 6876 -j ACCEPT
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

$PREFIX/../vpnutils/ipset-chn-networks.sh
