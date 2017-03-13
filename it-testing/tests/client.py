import json
from urllib2 import urlopen


class Client(object):
    def request(self, url):
        response = urlopen(url)
        raw_data = response.read().decode('utf-8')
        return json.loads(raw_data)
