#!/usr/bin/env python
from __future__ import division, print_function, unicode_literals

from flask import Flask, render_template

from module_base import register_imported_modules, Module
from modules import *

app = Flask(__name__)
register_imported_modules(app)

@app.route("/")
def hello_world():
    return render_template("index.html")

if __name__ == '__main__':
    app.run(debug=True)
