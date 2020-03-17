#!/usr/bin/env python

import json
import urllib2
import os

from bottle import route, run, template
from bottle import get, request, response

URL_JVB_METRICS="http://localhost:8080/colibri/stats"
BIND_IP = '0.0.0.0'
BIND_PORT = 8082

URL_REPO_EXPORTER_CONFIG="https://raw.githubusercontent.com/iorestoacasa-work/docker-jitsi-meet/master/exporter_config.yml"
PARAMS_TMPL = ""

# Utility to prepare iorestoacasa.work data export template
def prepare_params_tmpl(data):
    """
    PARAMS_TMPL acts as a cache to avoid unneed http requests
    """

    global PARAMS_TMPL
    if PARAMS_TMPL == "":
        r = urllib2.urlopen(URL_REPO_EXPORTER_CONFIG)
        # convert data to template
        params_tmpl = ""
        for line in r.read().split("\n"):
            if line.startswith("- name:"):
                param_name = line.split(" ")[2]
                if param_name in data:
                    params_tmpl += "jitsi.%s = %s\n" % (param_name, '%('+param_name+')s')

        PARAMS_TMPL = params_tmpl

    return PARAMS_TMPL


@route('/stats/')
def iorestoacasa_exporter():
    """
    Gets Jvb metrics from the internal API
    and presents them in prometheus format
    """

    r = urllib2.urlopen(URL_JVB_METRICS)
    if r.getcode() == 200:
        data = json.loads(r.read())
        params_tmpl = prepare_params_tmpl(data)
        return params_tmpl % data

    else:
        # If error occurs return HTTP response with the error of the original API
        response.status = r.getcode()
        return r.read()

run(host=BIND_IP, port=BIND_PORT)
