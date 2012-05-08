#!/bin/bash

set -eu

base="$(dirname "$(readlink -m "$0")")"

. $base/openvpn-env.sh

openvpn $params $*

