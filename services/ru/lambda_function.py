import json
from typing import Any

import requests
from utils import helpers


def lambda_handler(event: Any, context: Any) -> None:
    for record in event["Records"]:
        body = json.loads(record["body"])
        print("Service", helpers.upper("ru"))

        url = body["webhook_url"]

        try:
            response = requests.get(url, timeout=5)
            response.raise_for_status()

            print("HTTP GET status:", response.status_code)

        except requests.exceptions.RequestException as e:
            print("HTTP GET failed:", str(e))
