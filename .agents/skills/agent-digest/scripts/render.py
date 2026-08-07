#!/usr/bin/env python3
"""Render an agent-digest report.json into the markdown report or an HTML email, using a chosen template.

Templates use a mustache subset. `{{token}}` inserts a value, HTML-escaped in .html templates and verbatim in .md
ones. `{{#name}}` repeats its body once per list entry, or once when a scalar is truthy; `{{^name}}` renders its
body only when the value is empty, which is how fallback lines work. `{{! ... }}` is a comment and is stripped.
A section either stands alone on its own lines, in which case the tag lines vanish from the output, or opens and
closes within one line for an optional fragment such as a link. Inside a list body the entry's own keys win, and
`{{.}}` is the entry itself when the list holds plain strings.

report.json carries the digest: issue, start_date, end_date, summary, preview_text, health, target, plus
proposals (number, title, score, source, source_url, what, why, file, diff), radar (name, url, note), and noted
(strings). Every key is optional. score_color, score_background, score_text, title, dates and apply_command are
derived here, so a template never computes them and the report never repeats them.
"""

import argparse
import html
import json
import re
import sys
from pathlib import Path
from urllib.parse import urlsplit

BUNDLED = Path(__file__).resolve().parent.parent / "assets" / "templates"
LOCAL_TEMPLATES = ".agent-digest/templates"
CONFIG = ".agent-digest/config.json"
DEFAULT_TEMPLATE = "default"
# Email templates keep .html; the markdown one ends in .md.tmpl so a repository's markdown formatter cannot reflow its tag lines.
EMAIL_SUFFIX = ".html"
SUFFIXES = (EMAIL_SUFFIX, ".md.tmpl")
SAFE_SCHEMES = ("http", "https")
PREVIEW_LIMIT = 150
MISSING = object()

SCORES = {
    "high": {"score_color": "#15803d", "score_background": "#dafbe1", "score_text": "#1a7f37"},
    "medium": {"score_color": "#b45309", "score_background": "#fff8c5", "score_text": "#9a6700"},
    "low": {"score_color": "#52525b", "score_background": "#f6f8fa", "score_text": "#59636e"},
}
REPORT_DEFAULTS = {
    "issue": "",
    "start_date": "",
    "end_date": "",
    "summary": "",
    "preview_text": "",
    "health": "All sources healthy.",
    "target": "",
}
PROPOSAL_DEFAULTS = {
    "number": "",
    "title": "",
    "score": "low",
    "source": "",
    "source_url": "",
    "what": "",
    "why": "",
    "file": "",
    "diff": "",
}
RADAR_DEFAULTS = {"name": "", "url": "", "note": ""}

BLOCK = re.compile(
    r"^[ \t]*\{\{([#^])\s*([\w.]+)\s*\}\}[ \t]*\n(.*?)^[ \t]*\{\{/\s*\2\s*\}\}[ \t]*\n",
    re.DOTALL | re.MULTILINE,
)
INLINE = re.compile(r"\{\{([#^])\s*([\w.]+)\s*\}\}(.*?)\{\{/\s*\2\s*\}\}")
TOKEN = re.compile(r"\{\{\s*([\w.]+)\s*\}\}")
COMMENT = re.compile(r"^[ \t]*\{\{!(.*?)\}\}[ \t]*\n|\{\{!(.*?)\}\}", re.DOTALL | re.MULTILINE)


def safe_url(value):
    text = str(value or "").strip()
    try:
        scheme = urlsplit(text).scheme.lower()
    except ValueError:
        return ""
    # Feed content is untrusted and the rendered HTML is meant to be archivable, so a javascript: href never survives.
    return text if scheme in SAFE_SCHEMES else ""


def first_sentence(text):
    stripped = str(text or "").strip()
    found = re.search(r"^.*?[.!?](?=\s|$)", stripped, re.DOTALL)
    return (found.group(0) if found else stripped)[:PREVIEW_LIMIT]


def derive(report):
    context = dict(REPORT_DEFAULTS)
    context.update({key: value for key, value in report.items() if value is not None})

    proposals = []
    for index, entry in enumerate(report.get("proposals") or [], 1):
        item = dict(PROPOSAL_DEFAULTS)
        item.update({key: value for key, value in entry.items() if value is not None})
        item["number"] = item["number"] or index
        item["source_url"] = safe_url(item["source_url"])
        item.update(SCORES.get(str(item["score"]).lower(), SCORES["low"]))
        proposals.append(item)
    context["proposals"] = proposals

    radar = []
    for entry in report.get("radar") or []:
        item = dict(RADAR_DEFAULTS)
        item.update({key: value for key, value in entry.items() if value is not None})
        item["url"] = safe_url(item["url"])
        radar.append(item)
    context["radar"] = radar
    context["noted"] = [str(entry) for entry in report.get("noted") or []]

    issue = context["issue"]
    context["title"] = "Weekly digest #{0}".format(issue) if issue else "Weekly digest"
    context["dates"] = "{0} to {1}".format(context["start_date"], context["end_date"])
    context["preview_text"] = context["preview_text"] or first_sentence(context["summary"])
    numbers = ",".join(str(item["number"]) for item in proposals[:2]) or "1"
    target = " --target {0}".format(context["target"]) if context["target"] else ""
    context["apply_command"] = 'claude "/agent-digest apply #{0} {1}{2}"'.format(issue or 1, numbers, target)
    # A quiet week has nothing to apply, so templates hide the command rather than pointing at a proposal that does not exist.
    context["has_proposals"] = bool(proposals)
    return context


def substitute(text, context, escape):
    def one(match):
        name = match.group(1)
        value = context.get(name, MISSING)
        if value is MISSING:
            sys.exit("template uses unknown token {{{{{0}}}}}".format(name))
        if isinstance(value, (list, dict)):
            sys.exit("{{{{{0}}}}} is a section, not a value".format(name))
        return escape("" if value is None else str(value))

    return TOKEN.sub(one, text)


def scope(context, entry):
    child = dict(context)
    if isinstance(entry, dict):
        child.update(entry)
    else:
        child["."] = entry
    return child


def expand(match, context, escape):
    kind, name, body = match.group(1), match.group(2), match.group(3)
    value = context.get(name, MISSING)
    if value is MISSING:
        sys.exit("template uses unknown section {{{{{0}{1}}}}}".format(kind, name))
    if kind == "^":
        return render(body, context, escape) if not value else ""
    if isinstance(value, list):
        return "".join(render(body, scope(context, entry), escape) for entry in value)
    return render(body, context, escape) if value else ""


def next_section(template, start):
    block = BLOCK.search(template, start)
    inline = INLINE.search(template, start)
    if block and inline:
        return block if block.start() <= inline.start() else inline
    return block or inline


def render(template, context, escape):
    """Walk the template once, so rendered values are never rescanned and a diff containing {{tokens}} stays literal."""
    parts = []
    position = 0
    while True:
        match = next_section(template, position)
        if match is None:
            break
        parts.append(substitute(template[position : match.start()], context, escape))
        parts.append(expand(match, context, escape))
        position = match.end()
    parts.append(substitute(template[position:], context, escape))
    return "".join(parts)


def describe(path):
    found = COMMENT.search(path.read_text(encoding="utf-8"))
    text = ((found.group(1) or found.group(2) or "") if found else "").strip()
    return text.splitlines()[0] if text else ""


def template_name(path):
    for suffix in SUFFIXES:
        if path.name.endswith(suffix):
            return path.name[: -len(suffix)]
    return path.stem


def directories(target):
    return ([Path(target) / LOCAL_TEMPLATES] if target else []) + [BUNDLED]


def find_template(name, target):
    if not re.match(r"^[\w-]+$", name or ""):
        sys.exit("invalid template name: {0}".format(name))
    for directory in directories(target):
        for suffix in SUFFIXES:
            candidate = directory / (name + suffix)
            if candidate.is_file():
                return candidate
    sys.exit("no template named {0} in {1}".format(name, ", ".join(str(item) for item in directories(target))))


def configured_template(target):
    if not target:
        return None
    path = Path(target) / CONFIG
    if not path.is_file():
        return None
    try:
        return (json.loads(path.read_text(encoding="utf-8")) or {}).get("template")
    except ValueError as error:
        sys.exit("{0}: {1}".format(path, error))


def list_templates(target):
    """List the email templates only: the markdown report is fixed and is never a choice."""
    seen = {}
    for directory in directories(target):
        if not directory.is_dir():
            continue
        for path in sorted(directory.glob("*" + EMAIL_SUFFIX)):
            seen.setdefault(template_name(path), path)
    for name in sorted(seen):
        print("{0:<10} {1}".format(name, describe(seen[name])))


def main():
    parser = argparse.ArgumentParser(description="Render an agent-digest report.json through a template.")
    parser.add_argument("report", type=Path, nargs="?", help="report.json describing the digest, or - for stdin")
    parser.add_argument("--template", help="template name (default: the target's config, else " + DEFAULT_TEMPLATE + ")")
    parser.add_argument("--target", help="repository supplying " + CONFIG + " and any template in " + LOCAL_TEMPLATES)
    parser.add_argument("--output", type=Path, help="write here instead of stdout")
    parser.add_argument("--list", action="store_true", help="list the available templates and exit")
    args = parser.parse_args()

    if args.list:
        list_templates(args.target)
        return
    if args.report is None:
        parser.error("a report.json is required unless --list is given")

    path = find_template(args.template or configured_template(args.target) or DEFAULT_TEMPLATE, args.target)
    raw = sys.stdin.read() if str(args.report) == "-" else args.report.read_text(encoding="utf-8")
    try:
        report = json.loads(raw)
    except ValueError as error:
        sys.exit("report is not valid JSON: {0}".format(error))
    if not isinstance(report, dict):
        sys.exit("report must be a JSON object")

    escape = (lambda value: html.escape(value, quote=True)) if path.suffix == EMAIL_SUFFIX else (lambda value: value)
    output = render(COMMENT.sub("", path.read_text(encoding="utf-8")), derive(report), escape)
    if args.output:
        args.output.write_text(output, encoding="utf-8")
        print("{0} rendered with {1}".format(args.output, template_name(path)))
    else:
        sys.stdout.write(output)


if __name__ == "__main__":
    main()
