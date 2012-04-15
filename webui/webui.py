#!/usr/bin/env python
from __future__ import division, print_function, unicode_literals

from flask import Flask
app = Flask(__name__)

@app.route("/")
def hello_world():
    return "It works!"

if __name__ == '__main__':
    app.run(debug=True)
