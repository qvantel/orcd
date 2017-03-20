from config import *

def format_url_with_target(target):
    url = "http://" + graphite_host + ":" + graphite_port + "/render?target=" + target + "&format=json&from=-50s&until"
    return url
