import json
from typing import Any

import requests
from utils import helpers


class ProcessingError(Exception):
    """Custom error to mark message processing failures."""

    pass


def lambda_handler(event: dict[str, Any], context: Any) -> None:
    # If ANY record fails, we raise and let Lambda fail.
    # SQS will then retry the whole batch.
    for record in event["Records"]:
        message_id = record.get("messageId", "<no-id>")
        print(f"Processing SQS message {message_id}")

        try:
            _process_record(record)
            print(f"Message {message_id} processed successfully")

        except ProcessingError as e:
            # Our "business" failure -> we WANT SQS to retry / DLQ it
            print(f"ProcessingError for message {message_id}: {e}")
            raise  # ❗ VERY IMPORTANT: make Lambda fail

        except Exception as e:
            # Unexpected error -> also fail the Lambda
            print(f"Unexpected error for message {message_id}: {e}")
            raise  # ❗ Also fail so SQS retries / DLQs


def _process_record(record: dict[str, Any]) -> None:
    # 1) Parse body
    try:
        body = json.loads(record["body"])
    except (KeyError, json.JSONDecodeError) as e:
        raise ProcessingError(f"Invalid or missing JSON body: {e}") from e

    print("Service", helpers.upper("ru"))

    # 2) Validate payload
    url = body.get("webhook_url")
    if not url:
        raise ProcessingError("Missing 'webhook_url' in message body")

    # 3) Do HTTP call
    try:
        response = requests.get(url, timeout=5)
    except requests.exceptions.RequestException as e:
        # Network / timeout / DNS issues etc -> treat as fail
        raise ProcessingError(f"HTTP GET failed: {e}") from e

    # 4) Check HTTP status
    if not (200 <= response.status_code < 300):
        raise ProcessingError(f"Non-2xx response from {url}: {response.status_code}")

    print(f"HTTP GET success. Status: {response.status_code}")
