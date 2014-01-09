#!/bin/bash

initctl emit vpn-event EVENT=vpn_switch IP=$1 REASON=manual
