#!/bin/bash

IP=192.168.1.109

while [ 1 ]; do
    loss=101
    loss=$(ping -c10 $IP | grep -Eo "[0-9]+%" | tr -d %) 2>&1
    if [ "$loss" -gt "80" ]; then
        shutdown -r now
        exit 0
    else
        echo $loss% loss
    fi
done
