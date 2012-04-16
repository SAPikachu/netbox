#!/usr/bin/env python

# Requires python-daemon (http://pypi.python.org/pypi/python-daemon/)

from __future__ import division, print_function, unicode_literals

import os
import sys

from daemon.runner import DaemonRunner

PREFIX = os.path.abspath(os.path.dirname(__file__))

class WebUIDaemon(object):
    def __init__(self):
        self.stdin_path = os.devnull
        # self.stdout_path = os.devnull
        self.stdout_path = os.path.join(PREFIX, "/var/log/webui.log")
        self.stderr_path = self.stdout_path

        self.pidfile_path = "/var/run/webui.pid"
        self.pidfile_timeout = 1

    def run(self):
        sys.path.append(PREFIX)
        # Flask's reloader forks using sys.argv, set it to the actual entry-point since we can't run the daemon script again
        sys.argv = [os.path.join(PREFIX, "webui.py")]
        from webui import app
        app.run(debug=True)

if __name__ == "__main__":
    sys.argv[0] = os.path.abspath(sys.argv[0])
    DaemonRunner(WebUIDaemon()).do_action()
