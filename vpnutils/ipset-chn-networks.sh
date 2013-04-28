#!/bin/bash

SET_NAME=chnnetworks

ipset -exist create $SET_NAME hash:net hashsize 4096
ipset flush $SET_NAME

if [ "x$1" == "x--empty-set-only" ]; then
    exit 0;
fi

PREFIX=$(dirname "$(readlink -m "$0")")
RAW_NET_LIST=$PREFIX/chn_networks.txt
IPSET_RULE_FILE=$PREFIX/chn_networks.ipsetrules

if [  -f $IPSET_RULE_FILE ] && [ $IPSET_RULE_FILE -nt $RAW_NET_LIST ]; then
    cat $IPSET_RULE_FILE | grep -v "^create" | ipset restore
else 
    cat $RAW_NET_LIST | xargs -n 1 ipset add $SET_NAME
    ipset save $SET_NAME > $IPSET_RULE_FILE
fi

