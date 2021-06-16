from pathlib import Path


def pytest_addoption(parser):
    parser.addoption(
        "--jsondir",
        action="store",
        default="examples",
        help="eKYC-IDA WG Tests: Root directory of JSON files to test; should contain the directories 'request' and 'response'.",
    )


def pytest_generate_tests(metafunc):
    json_root = metafunc.config.getoption("jsondir")
    REQUEST_EXAMPLES = list(
        Path(__file__).parent.glob(f"../{json_root}/request/*.json")
    )

    if "request_example" in metafunc.fixturenames:
        metafunc.parametrize(
            "request_example",
            REQUEST_EXAMPLES,
            ids=list(x.name for x in REQUEST_EXAMPLES),
        )
    if "response_example" in metafunc.fixturenames:
        metafunc.parametrize(
            "response_example",
            RESPONSE_EXAMPLES,
            ids=list(x.name for x in RESPONSE_EXAMPLES),
        )
