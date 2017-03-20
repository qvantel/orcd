import unittest
import sys
sys.path.append('..')
from client import Client
from utils import *


class CallTestCase(unittest.TestCase):
    """Test cases for Calls."""

    def setUp(self):
        self.client = Client()

    def test_call_data_destinations_se(self):
        """Testing response of qvantel.call.destination.se."""
        response = self.client.request(format_url_with_target("qvantel.call.data.destination.se"))
        self.assert_datapoints(response)

    def test_call_data_destinations_dk(self):
        """Testing response of qvantel.call.destination.dk."""
        response = self.client.request(format_url_with_target("qvantel.call.data.destination.dk"))
        self.assert_datapoints(response)

    def test_call_data_destinations_fi(self):
        """Testing response of qvantel.call.destination.fi."""
        response = self.client.request(format_url_with_target("qvantel.call.data.destination.fi"))
        self.assert_datapoints(response)

    def test_call_sms_destinations_se(self):
        """Testing response of qvantel.sms.destination.se."""
        response = self.client.request(format_url_with_target("qvantel.call.sms.destination.se"))
        self.assert_datapoints(response)

    def test_call_sms_destinations_dk(self):
        """Testing response of qvantel.sms.destination.dk."""
        response = self.client.request(format_url_with_target("qvantel.call.sms.destination.dk"))
        self.assert_datapoints(response)

    def test_call_sms_destinations_fi(self):
        """Testing response of qvantel.sms.destination.fi."""
        response = self.client.request(format_url_with_target("qvantel.call.sms.destination.fi"))
        self.assert_datapoints(response)

    def test_call_mms_destinations_se(self):
        """Testing response of qvantel.mms.destination.se."""
        response = self.client.request(format_url_with_target("qvantel.call.mms.destination.se"))
        self.assert_datapoints(response)

    def test_call_mms_destinations_dk(self):
        """Testing response of qvantel.mms.destination.dk."""
        response = self.client.request(format_url_with_target("qvantel.call.mms.destination.dk"))
        self.assert_datapoints(response)

    def test_call_mms_destinations_fi(self):
        """Testing response of qvantel.mms.destination.fi."""
        response = self.client.request(format_url_with_target("qvantel.call.mms.destination.fi"))
        self.assert_datapoints(response)

    def test_call_voice_destinations_se(self):
        """Testing response of qvantel.voice.destination.se."""
        response = self.client.request(format_url_with_target("qvantel.call.voice.destination.se"))
        self.assert_datapoints(response)

    def test_call_voice_destinations_dk(self):
        """Testing response of qvantel.voice.destination.dk."""
        response = self.client.request(format_url_with_target("qvantel.call.voice.destination.dk"))
        self.assert_datapoints(response)

    def test_call_voice_destinations_fi(self):
        """Testing response of qvantel.voice.destination.fi."""
        response = self.client.request(format_url_with_target("qvantel.call.voice.destination.fi"))
        self.assert_datapoints(response)

    def assert_datapoints(self, data):
        for element in data:
            for dp in element['datapoints'][0:2]: # Test the first two "null" values in the array
                self.assertNotEqual(dp[0], None, "Getting null value")

        
if __name__ == '__main__':
        unittest.main()

