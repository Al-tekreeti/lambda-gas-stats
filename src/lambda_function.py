import boto3
from botocore.exceptions import ClientError
import os
import logging
import uuid

from web_browser import WebBrowser

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client('s3')

def lambda_handler(event, context):
    logger.info('## ENVIRONMENT VARIABLES')
    logger.info(os.environ)

    #logger.info('## PATH INFO')
    #logger.info(os.listdir(path='/var/task/lib'))
 
    driver = WebBrowser()

    logger.info('## SCRAPE THE GAS STATION')
    data = driver.scrapeGasStation("https://www.google.com/maps/place/Shell/@43.4589335,-80.4821815,15z/data=!4m5!3m4!1s0x0:0xc1499b5a84c188b8!8m2!3d43.4589335!4d-80.4821815")
    logging.info(data)

    logger.info('## GET THE CSV FILE')
    fileName = driver.storeGasPrices(data)
    logging.info(fileName)

    logger.info('## UPLOAD TO S3')
    try:
        s3.upload_file(f'/tmp/{fileName}', os.environ['BUCKET'], fileName)
    except ClientError as e:
        logging.error(e)

    body = "Hello World!"
    driver.close()

    return {
        "statusCode": 200,
        "body": body
    }
