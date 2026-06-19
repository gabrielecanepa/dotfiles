#!/usr/bin/env python3
"""Estimate token counts for documentation files.

Used by the sync-docs skill to check agentic files against any token
budgets declared in AGENTS.md. Counts are estimates: the public
tokenizers approximate Claude's tokenizer closely enough for budgeting,
not for billing.

Usage:
    python count_tokens.py FILE [FILE ...]
    python count_tokens.py DIR            # globs common doc files
    python count_tokens.py FILE --json
    python count_tokens.py FILE --budget 2000   # exit 1 if any file exceeds
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

DOC_GLOBS = ("AGENTS.md", "CLAUDE.md", "*.md", "*.mdc", "*.markdown", "*.txt")


def collect(paths: list[str]) -> list[Path]:
    files: list[Path] = []
    for raw in paths:
        p = Path(raw)
        if p.is_dir():
            for pattern in DOC_GLOBS:
                files.extend(sorted(p.rglob(pattern)))
            continue
        if p.is_file():
            files.append(p)
            continue
        print(f"skip (not found): {raw}", file=sys.stderr)
    # de-dupe, keep order
    seen: set[Path] = set()
    unique: list[Path] = []
    for f in files:
        rp = f.resolve()
        if rp in seen:
            continue
        seen.add(rp)
        unique.append(f)
    return unique


def make_counter():
    """Return (count_fn, method_label). Prefers tiktoken, falls back to chars/4."""
    try:
        import tiktoken
    except ImportError:
        return (lambda text: max(1, round(len(text) / 4))), "chars/4 estimate"

    for enc_name in ("o200k_base", "cl100k_base"):
        try:
            enc = tiktoken.get_encoding(enc_name)
        except Exception:
            continue
        return (lambda text, _enc=enc: len(_enc.encode(text))), f"tiktoken/{enc_name}"

    return (lambda text: max(1, round(len(text) / 4))), "chars/4 estimate"


def main() -> int:
    parser = argparse.ArgumentParser(description="Estimate token counts for docs.")
    parser.add_argument("paths", nargs="+", help="files or directories")
    parser.add_argument("--json", action="store_true", help="emit JSON")
    parser.add_argument("--budget", type=int, default=None,
                        help="exit non-zero if any file exceeds this many tokens")
    args = parser.parse_args()

    files = collect(args.paths)
    if not files:
        print("no files to count", file=sys.stderr)
        return 2

    count, method = make_counter()

    rows = []
    for f in files:
        text = f.read_text(encoding="utf-8", errors="replace")
        tokens = count(text)
        rows.append({"path": str(f), "tokens": tokens, "lines": text.count("\n") + 1})

    over = [r for r in rows if args.budget is not None and r["tokens"] > args.budget]

    if args.json:
        print(json.dumps({"method": method, "budget": args.budget,
                          "files": rows, "over_budget": over}, indent=2))
    else:
        width = max((len(r["path"]) for r in rows), default=4)
        print(f"{'FILE'.ljust(width)}  TOKENS  LINES   (method: {method})")
        for r in rows:
            flag = "  OVER" if r in over else ""
            print(f"{r['path'].ljust(width)}  {r['tokens']:>6}  {r['lines']:>5}{flag}")
        total = sum(r["tokens"] for r in rows)
        print(f"{'TOTAL'.ljust(width)}  {total:>6}")

    return 1 if over else 0


if __name__ == "__main__":
    raise SystemExit(main())
