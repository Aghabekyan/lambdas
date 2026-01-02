import json
from typing import Any

from utils import helpers


def lambda_handler(event: Any, context: Any) -> None:
    for record in event["Records"]:
        body = json.loads(record["body"])
        print("Service", helpers.upper("am"))
        print("Received:", body)
        print("Event", event)
