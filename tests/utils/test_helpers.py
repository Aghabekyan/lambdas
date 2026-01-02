from utils import helpers


def test_upper_lowercase_to_uppercase() -> None:
    assert helpers.upper("us") == "US"
