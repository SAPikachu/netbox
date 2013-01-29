#!/bin/sh

ip route get $1 | head -1 | sed s/^$1//
