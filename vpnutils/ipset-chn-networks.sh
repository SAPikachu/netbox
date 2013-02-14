#!/bin/bash

SET_NAME=chnnetworks

ipset -exist create $SET_NAME hash:net hashsize 4096
ipset flush $SET_NAME

cat $(dirname "$(readlink -m "$0")")/chn_networks.txt | xargs -n 1 ipset add $SET_NAME

