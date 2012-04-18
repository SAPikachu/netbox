#!/bin/bash

set -eu

base="$(dirname "$(readlink -m "$0")")"

config_name=$(cat "$base/config_name")

cd "$base/config"

openvpn --config "$config_name" --dev tun0 --script-security 2 --route-noexec --route-up "$base/route-up.sh" --down "$base/down.sh" --management 127.0.0.1 56876 $*
