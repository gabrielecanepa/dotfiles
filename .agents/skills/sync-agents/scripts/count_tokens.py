#!/usr/bin/env python3
"""Measure agentic documentation against the context budgets.

Counts are estimates for context budgeting, not billing. The script prefers
tiktoken and falls back to a chars-per-token estimate. Each file gets a role
inferred from its path and frontmatter, and the role sets a token target and
cap plus the shared line rules. A cap breach fails the run; --strict also
fails on a target breach and is the acceptance gate after a rewrite.

Usage:
    python count_tokens.py FILE [FILE ...]
    python count_tokens.py FILE --role scoped-rule
    python count_tokens.py FILE --strict
    python count_tokens.py FILE ... --total-target 2500 --total-cap 3500
    python count_tokens.py SKILLS_DIR --catalog
    python count_tokens.py FILE --hook
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path
from typing import Callable

DOC_GLOBS = ("AGENTS.md", "CLAUDE.md", "*.md", "*.mdc", "*.markdown", "*.txt", "*.toml")
ROLES: dict[str, tuple[int, int]] = {
    "global": (800, 1200),
    "root-agents": (1200, 2000),
    "nested-agents": (500, 1000),
    "always-rule": (600, 1000),
    "scoped-rule": (1200, 2000),
    "reference": (3000, 6000),
    "skill": (2500, 4000),
    "definition": (600, 1000),
    "memory": (500, 800),
    "spec": (6000, 10000),
}
LINE_LENGTH = (160, 220)
SENTENCES_PER_ITEM = (2, 3)
ITEMS_PER_SECTION = (8, 12)
DESCRIPTION_CHARS = (200, 250)
CATALOG_CHARS = (5000, 6500)
LIST_ITEM = re.compile(r"^\s*([-*+]|\d+\.)\s")
NON_PROSE = re.compile(r"^\s*(#|\||```|~~~|---\s*$)")
SENTENCE_END = re.compile(r"[.!?](?=\s+[A-Z`\"'(]|$)")
ENTRYPOINTS = {"AGENTS.md", "CLAUDE.md", "copilot-instructions.md"}
MARKDOWN_SUFFIXES = {".md", ".mdc", ".mdx", ".markdown"}
GENERATED_BLOCK = re.compile(r"<!-- BEGIN:(\S+) -->.*?<!-- END:\1 -->\n?", re.DOTALL)


def read_measured(file: Path) -> str:
    """File text minus tool-generated blocks such as `nextjs-agent-rules`,
    which their generator rewrites on every run and this contract never edits.
    """
    return GENERATED_BLOCK.sub("", file.read_text(encoding="utf-8", errors="replace"))
HOME = Path.home().resolve()


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


def estimate_chars(text: str) -> int:
    """chars/4 with runs of spaces collapsed, since tokenizers encode a run of
    padding spaces as one or two tokens rather than one per four characters.
    """
    return max(1, round(len(re.sub(r" {2,}", " ", text)) / 4))


def make_counter() -> tuple[Callable[[str], int], str]:
    try:
        import tiktoken
    except ImportError:
        return estimate_chars, "chars/4 estimate"

    for encoding_name in ("o200k_base", "cl100k_base"):
        try:
            encoding = tiktoken.get_encoding(encoding_name)
        except Exception:
            continue
        return (
            lambda text, current=encoding: len(current.encode(text)),
            f"tiktoken/{encoding_name}",
        )

    return estimate_chars, "chars/4 estimate"


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

    return {key: value.strip("'\"") for key, value in metadata.items()}


def body_lines(text: str) -> list[str]:
    lines = text.splitlines()
    if lines and lines[0].strip() == "---":
        for index in range(1, len(lines)):
            if lines[index].strip() == "---":
                return lines[index + 1 :]
    return lines


def git_toplevel(path: Path) -> Path | None:
    try:
        out = subprocess.run(
            ["git", "-C", str(path.parent), "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            timeout=5,
            check=False,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    if out.returncode != 0:
        return None
    return Path(out.stdout.strip()).resolve()


def infer_role(path: Path, metadata: dict[str, str], text: str = "") -> str | None:
    if "\n!`" in text:
        return None
    resolved = path.resolve()
    parts = resolved.parts
    name = resolved.name
    if name == "MEMORY.md":
        return "memory"
    if name == "SKILL.md":
        return "skill"
    if name in ENTRYPOINTS:
        parent = resolved.parent
        if parent in {HOME / ".agents", HOME / ".claude", HOME / ".codex", HOME / ".copilot"}:
            return "global"
        top = git_toplevel(resolved)
        if top is None or parent == top or parent == top / ".github":
            return "root-agents"
        return "nested-agents"
    if "rules" in parts or "instructions" in parts:
        scope = metadata.get("paths") or metadata.get("applyTo") or metadata.get("globs")
        always = metadata.get("alwaysApply", "").lower() == "true"
        if scope and scope.strip("'\" ") != "**" and not always:
            return "scoped-rule"
        return "always-rule"
    if "references" in parts:
        return "reference"
    if "specs" in parts or "plans" in parts:
        return "spec"
    if any(segment in parts for segment in ("agents", "commands", "output-styles")) and (
        ".claude" in parts or ".codex" in parts
    ):
        return "definition"
    return None


def line_findings(text: str) -> tuple[dict[str, int], dict[str, int]]:
    """Return (target breaches, cap breaches) for the line rules."""
    target: dict[str, int] = defaultdict(int)
    cap: dict[str, int] = defaultdict(int)
    in_fence = False
    items_in_section = 0
    for line in body_lines(text):
        stripped = line.strip()
        if stripped.startswith(("```", "~~~")):
            in_fence = not in_fence
            continue
        if in_fence or not stripped:
            continue
        if stripped.startswith("#"):
            items_in_section = 0
            continue
        if NON_PROSE.match(line):
            continue
        length = len(line)
        if length > LINE_LENGTH[1]:
            cap["line-length"] += 1
        elif length > LINE_LENGTH[0]:
            target["line-length"] += 1
        if LIST_ITEM.match(line):
            items_in_section += 1
            if items_in_section == ITEMS_PER_SECTION[1] + 1:
                cap["items-per-section"] += 1
            elif items_in_section == ITEMS_PER_SECTION[0] + 1:
                target["items-per-section"] += 1
            item_text = LIST_ITEM.sub("", stripped, count=1)
            sentences = len(SENTENCE_END.findall(re.sub(r"`[^`]*`", "x", item_text)))
            if sentences > SENTENCES_PER_ITEM[1]:
                cap["sentences-per-item"] += 1
            elif sentences > SENTENCES_PER_ITEM[0]:
                target["sentences-per-item"] += 1
    return dict(target), dict(cap)


def wrapped_prose(text: str) -> int:
    """Heuristic count of hard column wraps: physical line breaks inside a
    prose paragraph or list item, outside frontmatter and fences.
    """
    count = 0
    in_fence = False
    prev_prose = False
    for line in body_lines(text):
        stripped = line.strip()
        if stripped.startswith(("```", "~~~")):
            in_fence = not in_fence
            prev_prose = False
            continue
        if in_fence or not stripped or NON_PROSE.match(line):
            prev_prose = False
            continue
        if prev_prose and not LIST_ITEM.match(line):
            count += 1
        prev_prose = True
    return count


def measure(file: Path, count: Callable[[str], int], role_override: str | None) -> dict[str, object]:
    text = read_measured(file)
    metadata = frontmatter(text)
    role = role_override or infer_role(file, metadata, text)
    tokens = count(text)
    target_hits: list[str] = []
    cap_hits: list[str] = []
    if role:
        target, cap = ROLES[role]
        if tokens > cap:
            cap_hits.append(f"tokens {tokens}>{cap}")
        elif tokens > target:
            target_hits.append(f"tokens {tokens}>{target}")
    if file.suffix in MARKDOWN_SUFFIXES and "\n!`" not in text:
        line_target, line_cap = line_findings(text)
        if role == "memory":
            line_target.pop("items-per-section", None)
            line_cap.pop("items-per-section", None)
        target_hits.extend(f"{rule}:{n}" for rule, n in line_target.items())
        cap_hits.extend(f"{rule}:{n}" for rule, n in line_cap.items())
        wrapped = wrapped_prose(text)
        if wrapped:
            cap_hits.append(f"wrapped-prose:{wrapped}")
    return {
        "path": str(file),
        "role": role or "-",
        "tokens": tokens,
        "lines": max(1, len(text.splitlines())),
        "bytes": len(text.encode("utf-8")),
        "target": target_hits,
        "cap": cap_hits,
    }


def catalog_report(files: list[Path]) -> dict[str, object]:
    skills: list[dict[str, object]] = []
    names: defaultdict[str, list[str]] = defaultdict(list)
    for file in files:
        if file.name != "SKILL.md":
            continue
        text = read_measured(file)
        metadata = frontmatter(text)
        name = metadata.get("name", "")
        description = re.sub(r"\s+", " ", metadata.get("description", "")).strip()
        skills.append(
            {
                "path": str(file),
                "name": name,
                "description_chars": len(description),
                "over_target": len(description) > DESCRIPTION_CHARS[0],
                "over_cap": len(description) > DESCRIPTION_CHARS[1],
            }
        )
        if name:
            names[name.casefold()].append(str(file))

    total_chars = sum(int(skill["description_chars"]) for skill in skills)
    return {
        "skills": skills,
        "total_description_chars": total_chars,
        "target": CATALOG_CHARS[0],
        "cap": CATALOG_CHARS[1],
        "over_target": total_chars > CATALOG_CHARS[0],
        "over_cap": total_chars > CATALOG_CHARS[1],
        "duplicate_names": {name: paths for name, paths in names.items() if len(paths) > 1},
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Measure token budgets, line rules, wrapped prose, and skill discovery metadata."
    )
    parser.add_argument("paths", nargs="+", help="files or directories")
    parser.add_argument("--json", action="store_true", help="emit JSON")
    parser.add_argument("--role", choices=sorted(ROLES), help="override the inferred role for every file")
    parser.add_argument("--strict", action="store_true", help="fail on target breaches too")
    parser.add_argument("--total-target", type=int, help="combined token target")
    parser.add_argument("--total-cap", type=int, help="combined token cap")
    parser.add_argument("--catalog", action="store_true", help="audit SKILL.md metadata")
    parser.add_argument("--hook", action="store_true", help="one-line findings per file for hooks")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    files = collect(args.paths)
    if not files:
        print("no files to count", file=sys.stderr)
        return 2

    count, method = make_counter()
    rows = [measure(file, count, args.role) for file in files]
    total_tokens = sum(int(row["tokens"]) for row in rows)
    total_cap = args.total_cap is not None and total_tokens > args.total_cap
    total_target = args.total_target is not None and total_tokens > args.total_target
    catalog = catalog_report(files) if args.catalog else None

    cap_failed = any(row["cap"] for row in rows) or total_cap or bool(catalog and catalog["over_cap"])
    target_failed = any(row["target"] for row in rows) or total_target or bool(catalog and catalog["over_target"])
    failed = cap_failed or (args.strict and target_failed)

    if args.hook:
        for row in rows:
            for hit in row["cap"]:
                print(f"cap: {row['path']} [{row['role']}] {hit}")
            for hit in row["target"]:
                print(f"target: {row['path']} [{row['role']}] {hit}")
        return 1 if cap_failed else 0

    if args.json:
        print(
            json.dumps(
                {
                    "method": method,
                    "strict": args.strict,
                    "total_tokens": total_tokens,
                    "total_target": args.total_target,
                    "total_cap": args.total_cap,
                    "total_over_target": total_target,
                    "total_over_cap": total_cap,
                    "files": rows,
                    "catalog": catalog,
                },
                indent=2,
            )
        )
        return 1 if failed else 0

    width = max(len(str(row["path"])) for row in rows)
    print(f"{'FILE'.ljust(width)}  ROLE           TOKENS  LINES  STATUS  ({method})")
    for row in rows:
        status = []
        if row["cap"]:
            status.append("CAP " + ",".join(row["cap"]))
        if row["target"]:
            status.append("target " + ",".join(row["target"]))
        print(
            f"{str(row['path']).ljust(width)}  {str(row['role']).ljust(13)}  "
            f"{int(row['tokens']):>6}  {int(row['lines']):>5}  {'; '.join(status) or 'ok'}"
        )
    total_status = "CAP" if total_cap else "target" if total_target else "ok"
    print(f"{'TOTAL'.ljust(width)}  {'':13}  {total_tokens:>6}         {total_status}")

    if catalog:
        print(
            "CATALOG  "
            f"skills={len(catalog['skills'])}  "
            f"description_chars={catalog['total_description_chars']}  "
            f"target={catalog['target']}  cap={catalog['cap']}"
        )
        for skill in catalog["skills"]:
            if skill["over_target"]:
                level = "CAP" if skill["over_cap"] else "target"
                print(f"DESCRIPTION {level}  {skill['description_chars']:>4}  {skill['path']}")
        for name, paths in catalog["duplicate_names"].items():
            print(f"DUPLICATE NAME  {name}: {', '.join(paths)}")

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
