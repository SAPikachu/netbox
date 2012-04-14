#!/bin/bash

PREFIX=$(dirname $(readlink -m $0))

$PREFIX/openvpn.sh --daemon --log /var/log/openvpn $*

