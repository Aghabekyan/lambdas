from typing import Any
from unittest.mock import Mock

import pytest
import requests
from services.us.lambda_function import lambda_handler


def test_lambda_handler_success(
    sqs_event_factory: Any, capsys: Any, monkeypatch: pytest.MonkeyPatch
) -> None:
    body = {
        "webhook_url": "https://example.com",
    }

    event = sqs_event_factory(body=body, queue_suffix="us")

    # ---- mock requests.get ----
    mock_response = Mock()
    mock_response.status_code = 200
    mock_response.raise_for_status = Mock()

    monkeypatch.setattr(requests, "get", Mock(return_value=mock_response))

    lambda_handler(event, context=None)

    captured = capsys.readouterr()

    assert "Service US" in captured.out
    assert "HTTP GET status: 200" in captured.out
    requests.get.assert_called_once_with("https://example.com", timeout=5)


def test_lambda_handler_failure(
    sqs_event_factory: Any, capsys: Any, monkeypatch: pytest.MonkeyPatch
) -> None:
    body = {
        "webhook_url": "https://example.com",
    }

    event = sqs_event_factory(body=body, queue_suffix="us")

    # ---- mock failure ----
    def raise_request_error(*args, **kwargs) -> None:
        raise requests.exceptions.RequestException("boom")

    monkeypatch.setattr(requests, "get", raise_request_error)

    lambda_handler(event, context=None)

    captured = capsys.readouterr()

    assert "Service US" in captured.out
    assert "HTTP GET failed: boom" in captured.out
