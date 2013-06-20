#!/usr/bin/env python
import os
import sys
import subprocess


def main():
    param_keys = ("IP", "LABEL",)
    params = {key.lower(): os.getenv(key, None) for key in param_keys}
    kwargs = ":".join("{}={}".format(k, v) for k, v in params.items() if v)
    event = os.getenv("EVENT")
    control_path = os.path.join(
        os.path.dirname(__file__),
        "../vpn-failover/control.py",
    )
    sys.exit(subprocess.call(
        [control_path, event, "--kwargs", kwargs]
    ))


if __name__ == "__main__":
    main()

