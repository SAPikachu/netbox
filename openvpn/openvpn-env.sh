#!/bin/bash


config_name=$(cat "$base/config_name")
extra_params=

if [ -f "$base/extra_params" ]; then
    extra_params=$(cat "$base/extra_params")
fi

cd "$base/config"

params="--cd $PWD --config $config_name --tls-timeout 5 --dev tun0 --script-security 2 --route-noexec --up $base/up.sh --up-restart --down $base/down.sh --management 127.0.0.1 56876 $extra_params"

