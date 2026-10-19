#!/usr/bin/env python3

import argparse
from collections import defaultdict
from datetime import datetime, timedelta, timezone
import hashlib
import json
import math
import os
from pathlib import Path
import re
import sys

MAX_LINE = 8 * 1024 * 1024
MAX_FILE = 128 * 1024 * 1024


def parse_date(value):
  match = re.fullmatch(r"(\d+)([dwhm])", value)
  if match:
    seconds = int(match[1]) * {"d": 86400, "w": 604800, "h": 3600, "m": 60}[match[2]]
    return datetime.now(timezone.utc) - timedelta(seconds=seconds)
  date = datetime.fromisoformat(value.replace("Z", "+00:00"))
  return date.replace(tzinfo=date.tzinfo or timezone.utc).astimezone(timezone.utc)


def timestamp(value):
  try:
    if isinstance(value, (int, float)) and not isinstance(value, bool):
      return datetime.fromtimestamp(value / 1000, timezone.utc)
    if isinstance(value, str):
      return parse_date(value)
  except (ValueError, OverflowError, OSError):
    pass
  return None


def positive(value):
  number = int(value)
  if number < 1:
    raise argparse.ArgumentTypeError("Use a positive integer")
  return number


def encoded_cwd(cwd):
  return "--" + re.sub(r"[/\\:]", "-", re.sub(r"^[/\\]", "", str(cwd))) + "--"


def read_records(stream, path, issues):
  line_number = 0
  while True:
    line = stream.readline(MAX_LINE + 1)
    if not line:
      return
    line_number += 1
    oversized = len(line) > MAX_LINE
    if oversized:
      while line and not line.endswith(b"\n"):
        line = stream.readline(MAX_LINE + 1)
    try:
      record = None if oversized else json.loads(line)
      if not isinstance(record, dict):
        raise ValueError("Not an object")
    except (ValueError, UnicodeDecodeError):
      issues.append(f"{path.name}:{line_number}: skipped an invalid or oversized record")
      continue
    yield record


def discover(args, issues):
  agent_dir = Path(os.environ.get("PI_CODING_AGENT_DIR", "~/.pi/agent")).expanduser()
  override = args.sessions_dir or os.environ.get("PI_CODING_AGENT_SESSION_DIR")
  root = Path(override).expanduser().resolve() if override else agent_dir.resolve() / "sessions"
  project = Path(args.cwd or os.getcwd()).expanduser().resolve()
  scan = root if override or args.all_projects else root / encoded_cwd(project)
  if not scan.is_dir() or scan.is_symlink():
    return
  for directory, dirs, files in os.walk(scan, followlinks=False):
    dirs[:] = sorted(name for name in dirs if not (Path(directory) / name).is_symlink())
    for name in sorted(files):
      if not name.endswith(".jsonl"):
        continue
      path = Path(directory) / name
      if path.is_symlink() or not path.resolve().is_relative_to(root):
        continue
      nested = path.parent != root and not (path.parent.name.startswith("--") and path.parent.name.endswith("--"))
      if nested and not args.include_subagents:
        continue
      try:
        with path.open("rb") as stream:
          header_line = stream.readline(MAX_LINE + 1)
          header = json.loads(header_line) if len(header_line) <= MAX_LINE else None
        if not isinstance(header, dict) or header.get("type") != "session":
          raise ValueError("Missing session header")
        cwd = header.get("cwd")
        session_id = header.get("id")
        if not isinstance(cwd, str) or not isinstance(session_id, str):
          raise ValueError("Invalid session header")
        if not args.all_projects and Path(cwd).resolve() != project:
          continue
        started = timestamp(header.get("timestamp"))
        if args.since and (not started or started < args.since):
          continue
        if args.until and (not started or started > args.until):
          continue
        if args.session and not session_id.startswith(args.session):
          continue
        if path.stat().st_size > MAX_FILE:
          issues.append(f"{name}: skipped a session larger than 128 MiB")
          continue
        yield path, header
      except (OSError, ValueError, UnicodeDecodeError) as error:
        issues.append(f"{name}: skipped an unreadable or invalid session ({type(error).__name__})")


def records_for(path, issues):
  try:
    with path.open("rb") as stream:
      yield from read_records(stream, path, issues)
  except OSError:
    issues.append(f"{path.name}: could not read the session")


def number(value):
  if isinstance(value, bool) or not isinstance(value, (int, float)):
    return 0
  return value if math.isfinite(value) and value >= 0 else 0


def usage_for(record):
  if record.get("type") == "message":
    message = record.get("message")
    if not isinstance(message, dict) or message.get("role") != "assistant":
      return None
    source = message
  elif record.get("type") in ("usage", "compaction", "branch_summary"):
    source = record
  else:
    return None
  usage = source.get("usage")
  if not isinstance(usage, dict):
    return None
  return usage, str(source.get("provider") or "unknown"), str(source.get("model") or "unknown")


def cost_report(sessions, args, issues):
  groups = defaultdict(lambda: {"recorded_cost": 0, "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0, "usage_entries": 0, "unpriced_entries": 0})
  seen = set()
  duplicates = 0
  for path, header in sessions:
    for index, record in enumerate(records_for(path, issues)):
      result = usage_for(record)
      if result is None:
        continue
      usage, provider, model = result
      identity = [record.get("type"), record.get("id"), record.get("timestamp"), provider, model, usage]
      if not record.get("id"):
        identity.extend([str(path), index])
      key = hashlib.sha256(json.dumps(identity, sort_keys=True).encode()).digest()
      if key in seen:
        duplicates += 1
        continue
      seen.add(key)
      if args.by == "model":
        group = provider + "/" + model
      elif args.by == "project":
        group = header["cwd"]
      elif args.by == "session":
        group = header["id"]
      elif args.by == "day":
        date = timestamp(record.get("timestamp")) or timestamp(header.get("timestamp"))
        group = date.strftime("%Y-%m-%d") if date else "unknown"
      else:
        group = "all"
      row = groups[group]
      cost = usage.get("cost")
      if isinstance(cost, dict):
        row["recorded_cost"] += number(cost.get("total")) if "total" in cost else sum(number(cost.get(field)) for field in ("input", "output", "cacheRead", "cacheWrite"))
      else:
        row["unpriced_entries"] += 1
      for field in ("input", "output", "cacheRead", "cacheWrite"):
        row[field] += number(usage.get(field))
      row["usage_entries"] += 1
  total = sum(row["recorded_cost"] for row in groups.values())
  ordered = sorted(groups.items(), key=lambda item: item[0]) if args.by == "day" else sorted(groups.items(), key=lambda item: (-item[1]["recorded_cost"], item[0]))
  return {"label": "Recorded cost estimates, not invoices", "recorded_cost": round(total, 10), "sessions": len(sessions), "duplicate_usage_entries": duplicates, "grouping": args.by, "groups": dict(ordered[:args.limit]), "groups_omitted": max(0, len(groups) - args.limit)}


def message_text(message):
  content = message.get("content")
  if isinstance(content, str):
    return content
  if not isinstance(content, list):
    return ""
  return "\n".join(part["text"] for part in content if isinstance(part, dict) and part.get("type") == "text" and isinstance(part.get("text"), str))


def active_branch(records):
  entries = {record["id"]: record for record in records if isinstance(record.get("id"), str)}
  if not entries:
    return records
  current = next(reversed(entries))
  branch = []
  visited = set()
  while current in entries and current not in visited:
    visited.add(current)
    record = entries[current]
    branch.append(record)
    current = record.get("parentId")
  return list(reversed(branch))


def transcript_report(sessions, args, issues):
  if args.command == "show":
    if args.session and len(sessions) > 1:
      raise ValueError("The session prefix is ambiguous; use a longer prefix")
    sessions = sessions[:1]
  rows = []
  for path, header in sessions:
    records = records_for(path, issues)
    if args.command == "show":
      records = active_branch(list(records))
    for record in records:
      message = record.get("message")
      if record.get("type") != "message" or not isinstance(message, dict):
        continue
      role = message.get("role")
      roles = {"user"} if args.command == "prompts" else {"user", "assistant"}
      if args.command == "search" and args.role != "both":
        roles = {args.role}
      if args.command == "show" and args.include_tools:
        roles.add("toolResult")
      if role not in roles:
        continue
      text = message_text(message)
      if not text or (args.command == "search" and args.pattern.casefold() not in text.casefold()):
        continue
      if args.command == "search":
        start = max(0, text.casefold().find(args.pattern.casefold()) - args.max_chars // 4)
        text = text[start:]
      rows.append({"session_id": header["id"], "cwd": header["cwd"], "role": role, "timestamp": record.get("timestamp") or message.get("timestamp"), "text": text[:args.max_chars], "truncated": len(text) > args.max_chars})
      if args.command != "show" and len(rows) >= args.limit:
        return {"rows": rows, "limit_reached": True}
  omitted = max(0, len(rows) - args.limit)
  return {"rows": rows[-args.limit:] if args.command == "show" else rows, "rows_omitted": omitted}


def build_parser():
  parser = argparse.ArgumentParser(description="Read Pi session history on demand. Output is bounded JSON.")
  commands = parser.add_subparsers(dest="command", required=True)
  for command in ("cost", "prompts", "search", "show"):
    sub = commands.add_parser(command)
    scope = sub.add_mutually_exclusive_group()
    scope.add_argument("--cwd", help="Exact project directory; default: current directory")
    scope.add_argument("--all-projects", action="store_true", help="Read across projects only with explicit user permission")
    sub.add_argument("--sessions-dir", help="Override the Pi sessions root")
    sub.add_argument("--include-subagents", action="store_true")
    sub.add_argument("--since", type=parse_date)
    sub.add_argument("--until", type=parse_date)
    sub.add_argument("--session", help="Session ID or unique prefix within the selected scope")
    sub.add_argument("--limit", type=positive, default=20)
    sub.add_argument("--max-chars", type=positive, default=2000)
    if command == "cost":
      sub.add_argument("--by", choices=("total", "day", "project", "model", "session"), default="day")
    if command == "search":
      sub.add_argument("pattern")
      sub.add_argument("--role", choices=("user", "assistant", "both"), default="both")
    if command == "show":
      sub.add_argument("--include-tools", action="store_true")
  return parser


def main(argv=None):
  parser = build_parser()
  args = parser.parse_args(argv)
  if args.limit > 1000 or args.max_chars > 20000:
    parser.error("Limits cannot exceed 1000 rows or 20000 characters per row")
  if args.since and args.until and args.since > args.until:
    parser.error("--since must not be later than --until")
  issues = []
  sessions = list(discover(args, issues))
  sessions.sort(key=lambda item: timestamp(item[1].get("timestamp")) or datetime.min.replace(tzinfo=timezone.utc), reverse=True)
  try:
    report = cost_report(sessions, args, issues) if args.command == "cost" else transcript_report(sessions, args, issues)
  except ValueError as error:
    parser.error(str(error))
  report["scope"] = "all projects" if args.all_projects else str(Path(args.cwd or os.getcwd()).expanduser().resolve())
  report["skipped_records_or_sessions"] = len(issues)
  for issue in issues[:10]:
    print("Warning: " + issue, file=sys.stderr)
  if len(issues) > 10:
    print(f"Warning: {len(issues) - 10} further issues", file=sys.stderr)
  print(json.dumps(report, ensure_ascii=True, allow_nan=False, indent=2))
  return 0


if __name__ == "__main__":
  sys.exit(main())
