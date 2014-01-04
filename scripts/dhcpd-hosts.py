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


def format_pdnsd_record(ip, host):
    return """
rr {{
    name = {host};
    reverse = on;
    a = {ip};
    owner = {host};
    soa = localhost,root.localhost,42,60,30,600,60;
}}
""".format(host=host, ip=ip)


def main():
    hosts = {}
    hosts.update(hosts_from_file(
        "/var/lib/dhcp/dhcpd.leases",
        r"""^\s*lease\s+(?P<ip>[\d.]+)\s+{[^}]+client-hostname\s+"(?P<host>[^"]+)";"""
    ))
    hosts.update(hosts_from_file(
        "/etc/dhcp/dhcpd.conf",
        r"""^\s*host\s+(?P<host>[^ ]+)\s+{[^}]+fixed-address\s+(?P<ip>[\d.]+)(?:\s*,\s*[\d.]+)*\s*;"""
    ))

    [print(format_pdnsd_record(ip, host)) for host, ip in hosts.items()]

if __name__ == "__main__":
    main()
