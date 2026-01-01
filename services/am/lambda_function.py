import json
from utils import helpers


def lambda_handler(event, context):
    for record in event["Records"]:
        body = json.loads(record["body"])
        print("Service", "AM")
        print("Received:", body)
        print("Event", event)

