from __future__ import division, print_function, unicode_literals

import os
import glob
import subprocess
import socket
import re

from module_base import Module

def get_server_name(file_name):
    return os.path.splitext(os.path.basename(file_name))[0]

class OpenVPN(Module):
    def __init__(self, config):
        self.working_path = os.path.join(config["base_path"], "openvpn")
        self.config_name_path = os.path.join(self.working_path, "config_name")
        self.extra_params_path = os.path.join(self.working_path, "extra_params")

    def get_configuration(self):
        with open(self.config_name_path, "r") as f:
            selected_server = get_server_name(f.read().strip())

        selected_port = None
        if os.path.isfile(self.extra_params_path):
            with open(self.extra_params_path, "r") as f:
                m = re.search(r"--rport +(\d+)", f.read())
                if m:
                    selected_port = m.group(1)

        return {
            "servers": sorted([get_server_name(x) for x in glob.glob(
                os.path.join(self.working_path, "config", "*.ovpn")
            )]),
            "selected_server": selected_server,
            "selected_port": selected_port,
        }

    def select_server(self, server_name, port=None):
        file_name = server_name + ".ovpn"
        if not os.path.isfile(
            os.path.join(self.working_path, "config", file_name)
        ):
            raise ValueError("Invalid server name")

        with open(self.config_name_path, "w") as f:
            f.write(server_name + ".ovpn")

        if port:
            extra_params = ""
            if os.path.isfile(self.extra_params_path):
                with open(self.extra_params_path, "r") as f:
                    extra_params = f.read()

            extra_params = re.sub(r" *--rport +\d+", "", extra_params)
            extra_params += " --rport {}".format(port)
            with open(self.extra_params_path, "w") as f:
                f.write(extra_params)

        subprocess.call(
            ["sudo", "-n", "initctl", "stop", "openvpn-d"],
            close_fds=True,
        )
        subprocess.check_output(
            ["sudo", "-n", "initctl", "start", "openvpn-d"],
            stderr=subprocess.STDOUT,
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
