#!/usr/bin/env python

from __future__ import print_function

import sys
import re

def hosts_from_file(file_name, regexp):
    ret = {}
    with open(file_name, "r") as f:
        content = f.read()

    for m in re.finditer(regexp, content, re.M):
        ret[m.group("host")] = m.group("ip")

    return ret

def main():
    hosts = {}
    hosts.update(hosts_from_file(
        "/var/lib/dhcp/dhcpd.leases",
        r"""^\s*lease\s+(?P<ip>[\d.]+)\s+{[^}]+client-hostname\s+"(?P<host>[^"]+)";"""
    ))
    hosts.update(hosts_from_file(
        "/etc/dhcp/dhcpd.conf",
        r"""^\s*host\s+(?P<host>[^ ]+)\s+{[^}]+fixed-address\s+(?P<ip>[\d.]+)\s*;"""
    ))

    from pprint import pprint; pprint(hosts)

if __name__ == "__main__":
    main()
