#!/usr/bin/env python3
"""Send an agent-digest HTML report by email through the Resend API."""

import argparse
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

API_URL = "https://api.resend.com/emails"
DEFAULT_FROM = "Weekly digest <onboarding@resend.dev>"
USER_AGENT = "agent-digest/1.0"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("html", type=Path, help="path to the filled HTML email body")
    parser.add_argument("--subject", required=True)
    parser.add_argument("--issue", required=True, type=int, help="issue number reported by issue.py")
    parser.add_argument("--fingerprint", required=True, help="content fingerprint reported by issue.py")
    args = parser.parse_args()

    api_key = os.environ.get("RESEND_API_KEY")
    to = os.environ.get("AGENT_DIGEST_TO")
    if not api_key or not to:
        sys.exit("RESEND_API_KEY and AGENT_DIGEST_TO must be set in the environment")

    # The tags are the issue ledger: the next run reads them back to decide whether its content earns a new number.
    payload = {
        "from": os.environ.get("AGENT_DIGEST_FROM", DEFAULT_FROM),
        "to": [to],
        "subject": args.subject,
        "html": args.html.read_text(encoding="utf-8"),
        "tags": [
            {"name": "agent_digest_issue", "value": str(args.issue)},
            {"name": "agent_digest_fingerprint", "value": args.fingerprint},
        ],
    }
    request = urllib.request.Request(
        API_URL,
        data=json.dumps(payload).encode(),
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "User-Agent": USER_AGENT,
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            body = json.load(response)
    except urllib.error.HTTPError as error:
        sys.exit(f"resend api error {error.code}: {error.read().decode(errors='replace')}")
    print(f"sent: {body.get('id', body)}")


if __name__ == "__main__":
    main()
