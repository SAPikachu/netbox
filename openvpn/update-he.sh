#!/bin/bash

. $(dirname $(readlink -m $0))/../conf.sh

wget -q -O - "https://ipv4.tunnelbroker.net/nic/update?username=$HE_TUNNEL_USERNAME&password=$HE_TUNNEL_PASSWORD&hostname=$HE_TUNNEL_ID"
