from __future__ import division, print_function, unicode_literals

import os
import glob
import subprocess

from module_base import Module

def get_server_name(file_name):
    return os.path.splitext(os.path.basename(file_name))[0]

class OpenVPN(Module):
    def __init__(self, config):
        self.working_path = os.path.join(config["base_path"], "openvpn")
        self.config_name_path = os.path.join(self.working_path, "config_name")

    def get_configuration(self):
        with open(self.config_name_path, "r") as f:
            selected_server = get_server_name(f.read().strip())

        return {
            "servers": sorted([get_server_name(x) for x in glob.glob(
                os.path.join(self.working_path, "config", "*.ovpn")
            )]),
            "selected_server": selected_server,
        }

    def select_server(self, server_name):
        file_name = server_name + ".ovpn"
        if not os.path.isfile(
            os.path.join(self.working_path, "config", file_name)
        ):
            raise ValueError("Invalid server name")

        with open(self.config_name_path, "w") as f:
            f.write(server_name + ".ovpn")

        subprocess.check_call(["service", "openvpn-init.d", "restart"])

