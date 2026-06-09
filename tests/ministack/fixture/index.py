"""
Minimal Lambda handler used by the MiniStack integration test.

It reads the injected *_SECRET_ARN env vars and returns them so the
test harness can confirm they were wired up correctly by the module.
"""
import json
import os


def handler(event, context):
    secret_arns = {
        k: v for k, v in os.environ.items() if k.endswith("_SECRET_ARN")
    }
    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "hello from ministack test",
            "secret_arns": secret_arns,
        }),
    }
