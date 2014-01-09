#!/bin/bash

cd $(dirname $(readlink -m $0))
./chnroutes_build.py "{ip}/{mask}" 0 > chn_networks.txt
./ipset-chn-networks.sh

