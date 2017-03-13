import unittest
from client import Client


class ProductTestCase(unittest.TestCase):
    """Test cases for Products."""

    def setUp(self):
        self.client = Client()

    def test_product_data_plan_extra(self):
        """Testing response of qvantel.product.Dataplanextra."""
        url = "http://localhost:2000/render?target=qvantel.product.Dataplanextra&format=json&from=-50s&until"
        response = self.client.request(url)
        self.assert_datapoints(response)

    def test_product_data_plan_normal(self):
        """Testing response of qvantel.product.Dataplannormal."""
        url = "http://localhost:2000/render?target=qvantel.product.Dataplannormal&format=json&from=-50s&until"
        response = self.client.request(url)
        self.assert_datapoints(response)


    def test_product_data_plan_world(self):
        """Testing response of qvantel.product.Dataplanworld."""
        url = "http://localhost:2000/render?target=qvantel.product.Dataplanworld&format=json&from=-50s&until"
        response = self.client.request(url)
        self.assert_datapoints(response)

    def assert_datapoints(self, data):
        for element in data:
            for dp in element['datapoints'][0:3]: # Test the first three "null" values in the array
                self.assertNotEqual(dp[0], None, "Getting null value")


if __name__ == '__main__':
        unittest.main()

