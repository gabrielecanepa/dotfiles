#!/usr/bin/env python3
"""Print word, line, and average words-per-line counts for a text file."""

import sys


def stats(text):
    lines = text.splitlines()
    words = text.split()
    return {
        "lines": len(lines),
        "words": len(words),
        "words_per_line": len(words) / len(lines),
    }


def main():
    if len(sys.argv) != 2:
        print("usage: wordcount.py <file>", file=sys.stderr)
        return 1
    with open(sys.argv[1]) as f:
        result = stats(f.read())
    for key, value in result.items():
        print(f"{key}: {value}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
