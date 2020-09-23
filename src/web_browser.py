import os
from datetime import datetime
import csv
import uuid

from selenium import webdriver
from selenium.webdriver.common.by import By


class WebBrowser:
    def __init__(self):

        chrome_options = webdriver.ChromeOptions()
        
        chrome_options.add_argument('--headless')
        chrome_options.add_argument('--no-sandbox')
        chrome_options.add_argument('--disable-gpu')
        chrome_options.add_argument('--disable-dev-shm-usage')
        chrome_options.add_argument('--hide-scrollbars')
        chrome_options.add_argument('--enable-logging')
        chrome_options.add_argument('--log-level=0')
        chrome_options.add_argument('--v=99')
        chrome_options.add_argument('--single-process')
        chrome_options.add_argument('--ignore-certificate-errors')
        chrome_options.add_argument(
            'user-agent=Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.100 Safari/537.36')

        #chrome_options.binary_location = os.getcwd() + "/bin/headless-chromium"
        chrome_options.binary_location = "/opt/python/bin/headless-chromium"
        #self._driver = webdriver.Chrome(os.getcwd() + "/bin/chromedriver", chrome_options=chrome_options)
        self._driver = webdriver.Chrome("/opt/python//bin/chromedriver", chrome_options=chrome_options)
        
    def scrapeGasStation(self, url):
        """
        Scrape the prices of the Diesel, Regular, Midgrade, and Premium gas. 

        Arguments: 
        url -- the url of the page that holds the gas prices

        Returns:
        dict of the prices -- {Diesel: $$, Regular: $$, Midgrade: $$, Premium: $$}
        """
        self._driver.get(url)
        gas_prices_container = self._driver.find_element(By.CLASS_NAME, "section-gas-prices-container")

        # get the list of gas labels 
        labels = gas_prices_container.find_elements(By.CLASS_NAME, "section-gas-prices-label")
        labelsArr = [label.text for label in labels]

        # get the list of prices for all types of fuels
        prices = gas_prices_container.find_elements(By.TAG_NAME, "span")
        # ['', '$$', '', '$$', '', '$$', '', '$$'] --> [$$', $$', '$$', '$$']
        pricesArr = [price.text for price in prices if price.text not in ['', ' *']]

        return dict(zip(labelsArr, pricesArr)) # return a dictionary
    
    def storeGasPrices(self, labelledPrices):
        
        """ 
        Timestamp the scraped prices and store them in a csv file. 

        Arguments: 
        labelledPrices -- a dictionary of gas types with their prices, which is what the scrapeGasStation function returns

        Returns:
        fileName -- a csv file that holds the time-stamped labelled gas prices 
        """
        # create a file name that starts with randomized 6 hex numbers in /tmp/
        fileName = ''.join([str(uuid.uuid4().hex[:6]), 'gas_prices.csv'])

        with open(f'/tmp/{fileName}', 'a', newline='') as file:
            # add Date to the header of the file
            fieldNames = ['Diesel', 'Regular', 'Midgrade', 'Premium', 'Date']
            writer = csv.DictWriter(file, fieldnames=fieldNames)
            writer.writeheader()

            # time stamp the prices and write them in the file
            labelledPrices['Date'] = datetime.now() 
            writer.writerow(labelledPrices)
        
        # return file name
        return fileName

    def close(self):
        """ Close webdriver connection"""
        self._driver.quit()