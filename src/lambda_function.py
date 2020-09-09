import os
import logging
import uuid
from web_browser import WebBrowser

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    logger.info('## ENVIRONMENT VARIABLES')
    logger.info(os.environ)
 
    driver = WebBrowser()
    driver.get_url('https://www.google.com/')
    body = f"Headless Chrome Initialized, Page title: {driver._driver.title}"

    driver.close()

    return {
        "statusCode": 200,
        "body": body
    }
