#!/bin/bash

adduser --uid 1001 --gid 1001 --disabled-password --no-create-home webui
chown webui.webui webui.fcgi
chown root.root execwrap/execwrap
chmod 755 execwrap/execwrap
chmod +s execwrap/execwrap
chown root.webui ../openvpn/config_name
chmod 664 ../openvpn/config_name
chown root.webui ../openvpn/extra_params
chmod 664 ../openvpn/extra_params
