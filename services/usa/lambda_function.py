import json
import requests
from utils import helpers


def lambda_handler(event, context):
    for record in event["Records"]:
        body = json.loads(record["body"])
        print("Service", "USA")
        print("Received:", body)
        print("event", event)

        url = body["webhook_url"]

        try:
            response = requests.get(url, timeout=5)
            response.raise_for_status()

            print("HTTP GET status:", response.status_code)

        except requests.exceptions.RequestException as e:
            print("HTTP GET failed:", str(e))
