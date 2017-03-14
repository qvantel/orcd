import unittest
import sys
sys.path.append('..')
from client import Client


class CallTestCase(unittest.TestCase):
    """Test cases for Calls."""

    def setUp(self):
        self.client = Client()

    def test_call_data_destinations_se(self):
        """Testing response of qvantel.call.destination.se."""
        url = "http://localhost:2000/render?target=qvantel.call.data.destination.se&format=json&from=-50s&until"
        response = self.client.request(url)
        self.assert_datapoints(response)

    def test_call_data_destinations_dk(self):
        """Testing response of qvantel.call.destination.dk."""
        url = "http://localhost:2000/render?target=qvantel.call.data.destination.dk&format=json&from=-50s&until"
        response = self.client.request(url)
        self.assert_datapoints(response)

    def test_call_data_destinations_fi(self):
        """Testing response of qvantel.call.destination.fi."""
        url = "http://localhost:2000/render?target=qvantel.call.data.destination.fi&format=json&from=-50s&until"
        response = self.client.request(url)
        self.assert_datapoints(response)

    def test_call_sms_destinations_se(self):
        """Testing response of qvantel.sms.destination.se."""
        url = "http://localhost:2000/render?target=qvantel.call.sms.destination.se&format=json&from=-50s&until"
        response = self.client.request(url)
        self.assert_datapoints(response)

    def test_call_sms_destinations_dk(self):
        """Testing response of qvantel.sms.destination.dk."""
        url = "http://localhost:2000/render?target=qvantel.call.sms.destination.dk&format=json&from=-50s&until"
        response = self.client.request(url)
        self.assert_datapoints(response)

    def test_call_sms_destinations_fi(self):
        """Testing response of qvantel.sms.destination.fi."""
        url = "http://localhost:2000/render?target=qvantel.call.sms.destination.fi&format=json&from=-50s&until"
        response = self.client.request(url)
        self.assert_datapoints(response)

    def test_call_mms_destinations_se(self):
        """Testing response of qvantel.mms.destination.se."""
        url = "http://localhost:2000/render?target=qvantel.call.mms.destination.se&format=json&from=-50s&until"
        response = self.client.request(url)
        self.assert_datapoints(response)

    def test_call_mms_destinations_dk(self):
        """Testing response of qvantel.mms.destination.dk."""
        url = "http://localhost:2000/render?target=qvantel.call.mms.destination.dk&format=json&from=-50s&until"
        response = self.client.request(url)
        self.assert_datapoints(response)

    def test_call_mms_destinations_fi(self):
        """Testing response of qvantel.mms.destination.fi."""
        url = "http://localhost:2000/render?target=qvantel.call.mms.destination.fi&format=json&from=-50s&until"
        response = self.client.request(url)
        self.assert_datapoints(response)

    def test_call_voice_destinations_se(self):
        """Testing response of qvantel.voice.destination.se."""
        url = "http://localhost:2000/render?target=qvantel.call.voice.destination.se&format=json&from=-50s&until"
        response = self.client.request(url)
        self.assert_datapoints(response)

    def test_call_voice_destinations_dk(self):
        """Testing response of qvantel.voice.destination.dk."""
        url = "http://localhost:2000/render?target=qvantel.call.voice.destination.dk&format=json&from=-50s&until"
        response = self.client.request(url)
        self.assert_datapoints(response)

    def test_call_voice_destinations_fi(self):
        """Testing response of qvantel.voice.destination.fi."""
        url = "http://localhost:2000/render?target=qvantel.call.voice.destination.fi&format=json&from=-50s&until"
        response = self.client.request(url)
        self.assert_datapoints(response)

    def assert_datapoints(self, data):
        for element in data:
            for dp in element['datapoints'][0:2]: # Test the first two "null" values in the array
                self.assertNotEqual(dp[0], None, "Getting null value")

        
if __name__ == '__main__':
        unittest.main()

