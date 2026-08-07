#!/usr/bin/env python3
"""Resolve an agent-digest issue number from the emails already sent, reusing the last number when the report's content is unchanged.

The fingerprint covers report.json's proposals, radar and noted keys only, so a digest whose findings repeat last week's
keeps its number instead of consuming a new one.
"""

import argparse
import hashlib
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

API_URL = "https://api.resend.com/emails"
USER_AGENT = "agent-digest/1.0"
ISSUE_TAG = "agent_digest_issue"
FINGERPRINT_TAG = "agent_digest_fingerprint"
NUMBER = re.compile(r"#(\d+)\b")
# Keys that define an issue. Dates, summary wording, and feed failures differ between otherwise identical digests, so they stay out of the fingerprint.
SECTIONS = ("proposals", "radar", "noted")
LIST_LIMIT = 100
TIMEOUT = 30


def fingerprint(report):
    if not isinstance(report, dict):
        sys.exit("report must be a JSON object")
    missing = [key for key in SECTIONS if key not in report]
    if missing:
        sys.exit(f"report is missing required keys: {', '.join(missing)}")
    content = {key: report[key] for key in SECTIONS}
    canonical = json.dumps(content, sort_keys=True, ensure_ascii=False, separators=(",", ":"))
    return hashlib.sha256(canonical.encode()).hexdigest()


def api(path, api_key):
    request = urllib.request.Request(
        f"{API_URL}{path}", headers={"Authorization": f"Bearer {api_key}", "User-Agent": USER_AGENT}
    )
    with urllib.request.urlopen(request, timeout=TIMEOUT) as response:
        return json.load(response)


def last_sent(api_key, prefix):
    """Return the issue number and fingerprint of the most recent digest sent, or (0, None) when none exists."""
    listing = api(f"?limit={LIST_LIMIT}", api_key).get("data") or []
    sent = [item for item in listing if str(item.get("subject") or "").startswith(prefix)]
    sent.sort(key=lambda item: str(item.get("created_at") or ""), reverse=True)
    for item in sent:
        detail = api(f"/{urllib.parse.quote(str(item['id']))}", api_key)
        tags = {tag.get("name"): tag.get("value") for tag in (detail.get("tags") or [])}
        subject = NUMBER.search(str(detail.get("subject") or ""))
        # Issues sent before tagging carry their number in the subject only, so they increment rather than ever matching.
        number = tags.get(ISSUE_TAG) or (subject.group(1) if subject else "")
        if number.isdigit() and int(number) > 0:
            return int(number), tags.get(FINGERPRINT_TAG)
    return 0, None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path, required=True, help="report.json to fingerprint, or - for stdin")
    parser.add_argument("--prefix", default="Weekly digest", help="subject prefix identifying past issues")
    args = parser.parse_args()

    api_key = os.environ.get("RESEND_API_KEY")
    if not api_key:
        sys.exit("RESEND_API_KEY must be set in the environment")

    raw = sys.stdin.read() if str(args.report) == "-" else args.report.read_text(encoding="utf-8")
    try:
        current = fingerprint(json.loads(raw))
    except ValueError as error:
        sys.exit(f"report is not valid JSON: {error}")
    try:
        previous_issue, previous_fingerprint = last_sent(api_key, args.prefix)
    except urllib.error.HTTPError as error:
        sys.exit(f"resend api error {error.code}: {error.read().decode(errors='replace')}")
    except (urllib.error.URLError, TimeoutError, ValueError) as error:
        sys.exit(f"could not read the sent archive: {error}")

    reused = bool(previous_issue and previous_fingerprint == current)
    print(
        json.dumps(
            {
                "issue": previous_issue if reused else previous_issue + 1,
                "previous_issue": previous_issue,
                "reused": reused,
                "fingerprint": current,
            },
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
