from config import *

maps = {
    "callplannormal": "qvantel.products.voice.CallPlanNormal",
    "callsafter22": "qvantel.products.voice.CallsAfter22",
    "smsplannormal": "qvantel.products.sms.SMSPlanNormal",
    "mmsplannormal": "qvantel.products.mms.MMSPlanNormal",
    "freefacebook": "qvantel.products.data.FreeFacebook"
}

def format_url_with_target(target):
    url = "http://" + graphite_host + ":" + graphite_port + "/render?target=" + target + "&format=json&from=-50s&until"
    return url


# Returns the metric patch that Graphite uses.
def metric_path(metric):
    return maps[metric]
