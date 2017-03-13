import unittest
from client import Client


class CallTestCase(unittest.TestCase):
    """Test cases for Products."""

    def setUp(self):
        self.client = Client()

    def test_call_data_destinations_se(self):
        url = "http://localhost:2000/render?target=qvantel.call.data.destination.se&format=json&from=-50s&until"
        response = self.client.request(url)
        self.assert_datapoints(response)

    def assert_datapoints(self, data):
        for element in data:
            for dp in element['datapoints'][0:2]: # Test the first two "null" values in the array
                self.assertNotEqual(dp[0], None, "Getting null value")

        
if __name__ == '__main__':
        unittest.main()

