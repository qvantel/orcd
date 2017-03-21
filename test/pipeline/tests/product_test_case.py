import unittest
import sys
sys.path.append('..')
from client import Client
from utils import *


class ProductTestCase(unittest.TestCase):
    """Test cases for Products."""

    def setUp(self):
        self.client = Client()

    def test_product_data_plan_extra(self):
        """Testing response of qvantel.product.Dataplanextra."""
        response = self.client.request(format_url_with_target("qvantel.product.Dataplanextra"))
        self.assert_datapoints(response)

    def test_product_data_plan_normal(self):
        """Testing response of qvantel.product.Dataplannormal."""
        response = self.client.request(format_url_with_target("qvantel.product.Dataplannormal"))
        self.assert_datapoints(response)

    def test_product_data_plan_world(self):
        """Testing response of qvantel.product.Dataplanworld."""
        response = self.client.request(format_url_with_target("qvantel.product.Dataplanworld"))
        self.assert_datapoints(response)
        
    def assert_datapoints(self, data):
        for element in data:
            for dp in element['datapoints'][0:3]: # Test the first three "null" values in the array
                self.assertNotEqual(dp[0], None, "Getting null value")

if __name__ == '__main__':
        unittest.main()

