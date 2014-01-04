#!/bin/bash

BASE=$(dirname $(readlink -m $0))
cd $BASE

../scripts/dhcpd-hosts.py > /tmp/dhcpd-hosts.pdnsd
pdnsd-ctl include /tmp/dhcpd-hosts.pdnsd

