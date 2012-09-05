#!/usr/bin/env python
from __future__ import division, print_function, unicode_literals

import os

from flask import Flask, render_template

from module_base import register_imported_modules
from modules import *

app = Flask(__name__)
register_imported_modules(
    app, base_path=os.path.dirname(os.path.dirname(__file__))
)

@app.route("/")
@app.route("/<name>")
def page(name=""):
    return render_template((name or "index") + ".html")

if __name__ == '__main__':
    app.run(debug=True)
