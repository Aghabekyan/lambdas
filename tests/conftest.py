import json
from collections.abc import Callable
from typing import Any

import pytest


@pytest.fixture
def sqs_event_factory() -> Callable[[dict[str, Any], str], Any]:
    def _make(body: dict[str, Any], queue_suffix: str = "us") -> Any:
        body_str = json.dumps(body)

        return {
            "Records": [
                {
                    "messageId": "71a0d687-eb79-4f7a-9b7d-158fd7b6da34",
                    "receiptHandle": "AQEBIuNVIU3fwf60ry46T5oOBSIYXShg8mvIqoy+dHlC5tj8Gkg+qTuvcrIyGEO19jS4v5s6Zc9p65Sgsw/MCy/ol10iG/MG9kQv8olOKz97oTt3+WpiGDf4jl0mTJCf6xR/dHFWmMQF7n7KjU3EpeuwQCNDH5vt4QJmvvi2MSa29V34AylDTZT4RjtoJPFW3Vxc1EjJisNpi1AJzqCwE8oRitt3Ief3QhfyfZmOKzzPYTCsIXoYIlyNmvfrkYUfholkAJTeVt6onIv8iLotrO79Tyby1qOSR+tluWhSyiq/MFY73slI+6wwY0qu+XcrGOuASeAQSYDzKdXmFiv8n0ESrc8gYFEhfhXHlxc2EPqSy3ej33xoN8KeBu4nVckzK1AW/nUfkrQ6GMReZRZiD1+Azw==",
                    "body": body_str,
                    "attributes": {
                        "ApproximateReceiveCount": "1",
                        "AWSTraceHeader": "Root=1-6957dd3b-50ba78175f9cb4362900ec19",
                        "SentTimestamp": "1767365947411",
                        "SenderId": "AROA5S2AXLYIXQ6UZYCEU:BackplaneAssumeRoleSession",
                        "ApproximateFirstReceiveTimestamp": "1767365947417",
                    },
                    "messageAttributes": {},
                    "md5OfBody": "7cfe7c48e5d72035a837202eea6c900e",
                    "eventSource": "aws:sqs",
                    "eventSourceARN": f"arn:aws:sqs:us-east-1:933754265105:playground-events-{queue_suffix}",
                    "awsRegion": "us-east-1",
                }
            ]
        }

    return _make
