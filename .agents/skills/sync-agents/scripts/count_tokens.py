#!/usr/bin/env python3
"""Measure agentic documentation context and discovery metadata.

Counts are estimates for context budgeting, not billing. The script prefers
tiktoken and falls back to a chars-per-token estimate.

Usage:
    python count_tokens.py FILE [FILE ...]
    python count_tokens.py FILE --profile root-agents
    python count_tokens.py FILE --total-budget 3000
    python count_tokens.py SKILLS_DIR --catalog
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import defaultdict
from pathlib import Path
from typing import Callable

DOC_GLOBS = ("AGENTS.md", "CLAUDE.md", "*.md", "*.mdc", "*.markdown", "*.txt")
PROFILES = {
    "global": {"lines": 120, "tokens": 1500, "bytes": 6144},
    "root-agents": {"lines": 150, "tokens": 2000},
    "nested-agents": {"lines": 80, "tokens": 1000},
    "always-rule": {"lines": 60, "tokens": 1000},
    "scoped-rule": {"lines": 200, "tokens": 2000},
    "skill": {"lines": 300, "tokens": 4000},
    "spec": {"lines": 500, "tokens": 10000},
    "reference": {"lines": 500, "tokens": 8000},
}


def collect(paths: list[str]) -> list[Path]:
    files: list[Path] = []
    for raw in paths:
        path = Path(raw)
        if path.is_dir():
            for pattern in DOC_GLOBS:
                files.extend(sorted(path.rglob(pattern)))
        elif path.is_file():
            files.append(path)
        else:
            print(f"skip (not found): {raw}", file=sys.stderr)

    seen: set[Path] = set()
    unique: list[Path] = []
    for file in files:
        resolved = file.resolve()
        if resolved not in seen:
            seen.add(resolved)
            unique.append(file)
    return unique


def make_counter() -> tuple[Callable[[str], int], str]:
    try:
        import tiktoken
    except ImportError:
        return (lambda text: max(1, round(len(text) / 4))), "chars/4 estimate"

    for encoding_name in ("o200k_base", "cl100k_base"):
        try:
            encoding = tiktoken.get_encoding(encoding_name)
        except Exception:
            continue
        return (
            lambda text, current=encoding: len(current.encode(text)),
            f"tiktoken/{encoding_name}",
        )

    return (lambda text: max(1, round(len(text) / 4))), "chars/4 estimate"


def frontmatter(text: str) -> dict[str, str]:
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return {}

    metadata: dict[str, str] = {}
    current_key: str | None = None
    for line in lines[1:]:
        if line.strip() == "---":
            break
        match = re.match(r"^([A-Za-z][A-Za-z0-9_-]*):(?:\s*(.*))?$", line)
        if match:
            current_key = match.group(1)
            value = (match.group(2) or "").strip()
            metadata[current_key] = "" if value in {">", ">-", "|", "|-"} else value
            continue
        if current_key and line[:1].isspace():
            value = line.strip()
            if value:
                metadata[current_key] = " ".join(
                    part for part in (metadata[current_key], value) if part
                )
            continue
        current_key = None

    return {
        key: value.strip("'\"")
        for key, value in metadata.items()
    }


def limits_for(args: argparse.Namespace) -> dict[str, int | None]:
    limits: dict[str, int | None] = {"tokens": None, "lines": None, "bytes": None}
    if args.profile:
        limits.update(PROFILES[args.profile])
    if args.budget is not None:
        limits["tokens"] = args.budget
    if args.line_budget is not None:
        limits["lines"] = args.line_budget
    if args.byte_budget is not None:
        limits["bytes"] = args.byte_budget
    return limits


def over_reasons(row: dict[str, int | str], limits: dict[str, int | None]) -> list[str]:
    return [
        f"{metric}>{limit}"
        for metric, limit in limits.items()
        if limit is not None and int(row[metric]) > limit
    ]


def catalog_report(files: list[Path]) -> dict[str, object]:
    skills: list[dict[str, object]] = []
    names: defaultdict[str, list[str]] = defaultdict(list)
    for file in files:
        if file.name != "SKILL.md":
            continue
        text = file.read_text(encoding="utf-8", errors="replace")
        metadata = frontmatter(text)
        name = metadata.get("name", "")
        description = re.sub(r"\s+", " ", metadata.get("description", "")).strip()
        skills.append(
            {
                "path": str(file),
                "name": name,
                "description_chars": len(description),
                "over_description_target": len(description) > 300,
            }
        )
        if name:
            names[name.casefold()].append(str(file))

    total_chars = sum(int(skill["description_chars"]) for skill in skills)
    return {
        "skills": skills,
        "total_description_chars": total_chars,
        "target": 6000,
        "limit": 8000,
        "over_target": total_chars > 6000,
        "over_limit": total_chars > 8000,
        "duplicate_names": {
            name: paths for name, paths in names.items() if len(paths) > 1
        },
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Measure lines, bytes, tokens, and skill discovery metadata."
    )
    parser.add_argument("paths", nargs="+", help="files or directories")
    parser.add_argument("--json", action="store_true", help="emit JSON")
    parser.add_argument("--profile", choices=sorted(PROFILES), help="apply default limits")
    parser.add_argument("--budget", type=int, help="per-file token limit")
    parser.add_argument("--line-budget", type=int, help="per-file line limit")
    parser.add_argument("--byte-budget", type=int, help="per-file UTF-8 byte limit")
    parser.add_argument("--total-budget", type=int, help="combined token limit")
    parser.add_argument("--catalog", action="store_true", help="audit SKILL.md metadata")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    files = collect(args.paths)
    if not files:
        print("no files to count", file=sys.stderr)
        return 2

    count, method = make_counter()
    limits = limits_for(args)
    rows: list[dict[str, object]] = []
    for file in files:
        text = file.read_text(encoding="utf-8", errors="replace")
        row: dict[str, object] = {
            "path": str(file),
            "tokens": count(text),
            "lines": max(1, len(text.splitlines())),
            "bytes": len(text.encode("utf-8")),
        }
        row["over"] = over_reasons(row, limits)
        rows.append(row)

    total_tokens = sum(int(row["tokens"]) for row in rows)
    total_over = args.total_budget is not None and total_tokens > args.total_budget
    catalog = catalog_report(files) if args.catalog else None
    failed = any(row["over"] for row in rows) or total_over
    if catalog and catalog["over_limit"]:
        failed = True

    if args.json:
        print(
            json.dumps(
                {
                    "method": method,
                    "profile": args.profile,
                    "limits": limits,
                    "total_budget": args.total_budget,
                    "total_tokens": total_tokens,
                    "total_over": total_over,
                    "files": rows,
                    "catalog": catalog,
                },
                indent=2,
            )
        )
        return 1 if failed else 0

    width = max(len(str(row["path"])) for row in rows)
    print(f"{'FILE'.ljust(width)}  TOKENS  LINES   BYTES  STATUS  ({method})")
    for row in rows:
        reasons = ",".join(row["over"]) if row["over"] else "ok"
        print(
            f"{str(row['path']).ljust(width)}  {int(row['tokens']):>6}  "
            f"{int(row['lines']):>5}  {int(row['bytes']):>6}  {reasons}"
        )
    total_status = "OVER" if total_over else "ok"
    print(f"{'TOTAL'.ljust(width)}  {total_tokens:>6}                 {total_status}")

    if catalog:
        print(
            "CATALOG  "
            f"skills={len(catalog['skills'])}  "
            f"description_chars={catalog['total_description_chars']}  "
            f"target={catalog['target']}  limit={catalog['limit']}"
        )
        long_descriptions = [
            skill for skill in catalog["skills"] if skill["over_description_target"]
        ]
        for skill in long_descriptions:
            print(
                f"LONG DESCRIPTION  {skill['description_chars']:>4}  {skill['path']}"
            )
        for name, paths in catalog["duplicate_names"].items():
            print(f"DUPLICATE NAME  {name}: {', '.join(paths)}")

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
