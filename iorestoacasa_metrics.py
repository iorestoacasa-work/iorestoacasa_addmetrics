#!/usr/bin/env python
try:
    from urllib.request import urlopen, Request
except ImportError:
    from urllib2 import urlopen, Request

import json
import os

from bottle import route, run, template
from bottle import get, request, response

URL_JVB_METRICS="http://localhost:8080/colibri/stats"
BIND_IP = '0.0.0.0'
BIND_PORT = 8081


@route("/<url:re:.+>")
def iorestoacasa_exporter(url):
    """
    Gets Jvb metrics from the internal API
    and presents them in prometheus format
    """

    try:
        req = urlopen(Request(url=URL_JVB_METRICS))
        data = json.loads(req.read().decode('utf-8'))
        req.close()
        r = ""
        for key, value in data.items():
            if key in ['conference_sizes', 'current_timestamp', 'graceful_shutdown','conferences_by_audio_senders','conferences_by_video_senders','version']:
                continue
            r += "jitsi_{} {}\n".format(key, value)
        response.content_type = 'text/plain; charset=utf-8'
        return r
    except Exception as e:
        return str(e)

run(host=BIND_IP, port=BIND_PORT)
