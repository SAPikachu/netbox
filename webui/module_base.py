from __future__ import division, print_function, unicode_literals

import json
from abc import ABCMeta

from flask import request 

class Module(object):
    pass

def _wrap_method(app, method):
    def wrapped():
        params = dict(request.form)
        resp_content = json.dumps(method(**params))
        resp = app.make_response(unicode(resp_content))
        resp.mimetype = "application/json"
        return resp

    return wrapped

def register_imported_modules(app):
    for module_class in Module.__subclasses__():
        module_name = module_class.__name__.lower()
        instance = module_class()
        for member_name in dir(instance):
            member = getattr(instance, member_name)
            if member_name.startswith("_") or not callable(member):
                continue

            rule = r"/modules/{}/{}".format(module_name, member_name)
            app.add_url_rule(
                rule, rule, _wrap_method(app, member), methods=["POST"],
            )

