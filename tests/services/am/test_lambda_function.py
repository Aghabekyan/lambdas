import json
from typing import Any

from services.am.lambda_function import lambda_handler


def test_lambda_handler_ru_uses_body(sqs_event_factory: Any, capsys: Any) -> None:
    body = {
        "gender": "male",
        "net_income": 333,
        "webhook_url": "https://www.jetbrains.com/pycharm/download/download-thanks.html?platform=macM1",
    }

    event = sqs_event_factory(body=body, queue_suffix="am")

    lambda_handler(event, context=None)

    captured = capsys.readouterr()
    assert "Service AM" in captured.out  # or whatever helpers.upper("ru") prints
    assert f"Received: {json.loads(event['Records'][0]['body'])}" in captured.out
    assert f"Event {event}" in captured.out
