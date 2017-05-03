import unittest
import sys
sys.path.append('..')
from client import Client
from utils import *


class ProductTestCase(unittest.TestCase):
    """Test cases for Products."""


    def setUp(self):
        self.client = Client()


    def test_product_data_freefacebook(self):
        """Testing response of qvantel.product.data.FreeFacebook"""
        response = self.client.request(format_url_with_target(metric_path("freefacebook")))
        self.assert_datapoints(response)


    def test_product_voice_callsafter22(self):
        """Testing response of qvantel.product.voice.callsafter22"""
        response = self.client.request(format_url_with_target(metric_path("callsafter22")))
        self.assert_datapoints(response)


    def test_product_sms_smsplannormal(self):
        """Testing response of qvantel.product.sms.SMSPlanNormal"""
        response = self.client.request(format_url_with_target(metric_path("smsplannormal")))
        self.assert_datapoints(response)


    def test_product_mms_mmsplannormal(self):
        """Testing response of qvantel.product.mms.MMSPlanNormal"""
        response = self.client.request(format_url_with_target(metric_path("mmsplannormal")))
        self.assert_datapoints(response)


    def test_product_voice_callplannormal(self):
        """Testing response of qvantel.product.voice.callplannormal"""
        response = self.client.request(format_url_with_target(metric_path("callplannormal")))
        self.assert_datapoints(response)


    def assert_datapoints(self, data):
        for element in data:
            for dp in element['datapoints'][0:3]: # Test the first three "null" values in the array
                self.assertNotEqual(dp[0], None, "Getting null value")

if __name__ == '__main__':
        unittest.main()

