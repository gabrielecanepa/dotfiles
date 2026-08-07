#!/usr/bin/env python3
"""Fetch every rss source in feeds.json and print window-filtered items as JSON for the agent-digest skill."""

import argparse
import concurrent.futures
import json
import re
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime, timedelta, timezone
from email.utils import parsedate_to_datetime
from pathlib import Path

ATOM = "{http://www.w3.org/2005/Atom}"
USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
SUMMARY_LIMIT = 500


def parse_date(text):
    if not text:
        return None
    text = text.strip()
    try:
        parsed = parsedate_to_datetime(text)
    except (TypeError, ValueError):
        parsed = None
    if parsed is None:
        try:
            parsed = datetime.fromisoformat(text.replace("Z", "+00:00"))
        except ValueError:
            return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed


def text_of(node):
    return "".join(node.itertext()).strip() if node is not None else ""


def strip_html(text):
    return re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", text)).strip()


def parse_entries(raw):
    # A DTD is only active before the root element; refusing one there blocks XXE and entity-expansion attacks on the stdlib parser, while escaped markup inside items stays allowed.
    root_start = re.search(rb"<[A-Za-z]", raw)
    prolog = raw[: root_start.start()] if root_start else raw
    if b"<!DOCTYPE" in prolog or b"<!ENTITY" in prolog:
        raise ValueError("feed declares a DTD, refusing to parse")
    root = ET.fromstring(raw)
    entries = []
    for item in root.iter("item"):
        entries.append(
            {
                "title": text_of(item.find("title")),
                "url": text_of(item.find("link")),
                "date": parse_date(text_of(item.find("pubDate"))),
                "summary": strip_html(text_of(item.find("description"))),
            }
        )
    for entry in root.iter(f"{ATOM}entry"):
        link = entry.find(f"{ATOM}link[@rel='alternate']")
        if link is None:
            link = entry.find(f"{ATOM}link")
        entries.append(
            {
                "title": text_of(entry.find(f"{ATOM}title")),
                "url": link.get("href", "") if link is not None else "",
                "date": parse_date(text_of(entry.find(f"{ATOM}published")) or text_of(entry.find(f"{ATOM}updated"))),
                "summary": strip_html(text_of(entry.find(f"{ATOM}summary")) or text_of(entry.find(f"{ATOM}content"))),
            }
        )
    return entries


def fetch_source(source, since):
    request = urllib.request.Request(source["url"], headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=20) as response:
        raw = response.read()
    items = []
    for entry in parse_entries(raw):
        if entry["date"] is None or entry["date"] < since:
            continue
        item = {
            "source": source["name"],
            "title": entry["title"],
            "url": entry["url"],
            "date": entry["date"].isoformat(),
        }
        if not source.get("skim") and entry["summary"]:
            item["summary"] = entry["summary"][:SUMMARY_LIMIT]
        items.append(item)
    return items


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--days", type=int, default=7, help="lookback window in days (default 7)")
    parser.add_argument("--feeds", type=Path, default=Path(__file__).resolve().parent.parent / "feeds.json")
    args = parser.parse_args()

    sources = json.loads(args.feeds.read_text())["sources"]
    since = datetime.now(timezone.utc) - timedelta(days=args.days)
    result = {"since": since.isoformat(), "items": [], "pages": [], "errors": []}

    rss_sources = [source for source in sources if source["type"] == "rss"]
    result["pages"] = [
        {"name": source["name"], "url": source["url"], "coverage": source.get("coverage", "")}
        for source in sources
        if source["type"] == "page"
    ]

    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        futures = {pool.submit(fetch_source, source, since): source for source in rss_sources}
        for future in concurrent.futures.as_completed(futures):
            source = futures[future]
            try:
                result["items"].extend(future.result())
            except Exception as error:
                result["errors"].append({"name": source["name"], "url": source["url"], "error": str(error)})

    result["items"].sort(key=lambda item: item["date"], reverse=True)
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
