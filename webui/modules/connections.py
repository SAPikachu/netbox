from __future__ import division, print_function, unicode_literals

import re
import os
import subprocess

from module_base import Module

class Connections(Module):
    def __init__(self, config):
        pass

    def _parse_peer(self, proto, parts):
        peer = {}
        fields = ["src", "dst"]
        if proto in ("tcp", "udp"):
            fields += ["sport", "dport"]

        for _ in range(len(fields)):
            m = re.match(r"^({})=(.+)$".format("|".join(fields)), parts.pop(0))
            key = m.group(1)
            value = m.group(2)
            if key.endswith("port"):
                value = int(value)

            peer[key] = value

        for _ in range(2):
            m = re.match(r"^(packets|bytes)=(\d+)$", parts[0])
            if m:
                parts.pop(0)
                peer[m.group(1)] = int(m.group(2))

        return peer
    

    def get_connections(self):
        return self._get_connections_impl("ipv4") + \
               self._get_connections_impl("ipv6")
    
    def _get_connections_impl(self, family):
        connections = []
        p = subprocess.Popen(["sudo", "-n", "conntrack", "-L", "-f", family],
                            stdout=subprocess.PIPE,
                            close_fds=True,)
        for line in p.stdout:
            line = line.strip()
            if not line:
                continue

            parts = re.split(r"\s+", line)
            conn = {}

            if parts[0].startswith("ipv"):
                conn["version"] = parts[0]
                parts = parts[2:]

            conn["protocol"] = parts[0]
            parts = parts[2:]

            conn["timeout"] = int(parts.pop(0))

            if not parts[0].startswith("src="):
                conn["state"] = parts.pop(0)

            conn["tx"] = self._parse_peer(conn["protocol"], parts)
            if parts[0].startswith("["):
                conn["state2"] = parts.pop(0)[1:-1]

            conn["rx"] = self._parse_peer(conn["protocol"], parts)

            connections.append(conn)
                
        return connections
