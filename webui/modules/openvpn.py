from __future__ import division, print_function, unicode_literals

import os
import glob
import subprocess
import socket

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

        subprocess.check_call(
            ["initctl", "restart", "openvpn-d"],
            close_fds=True,
        )
    
    def get_status(self):
        try:
            s = socket.create_connection(("127.0.0.1", 56876), 1)
            f = s.makefile("w")
            f.readline()
            f.write("state\n")
            f.flush()
            content = f.readline()
            state = content.split(",")[1]
            f.readline()
            f.write("status\n")
            f.flush()
            f.readline()
            status_data = {}
            for line in f:
                line = line.strip()
                if line == "END":
                    break

                status_data.update([line.split(",", 2)])

            f.close()
            s.close()
            return {"state": state, "status_data": status_data}
        except socket.timeout:
            return {"state": "UNKNOWN"}
