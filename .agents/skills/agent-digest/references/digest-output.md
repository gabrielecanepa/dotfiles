# Digest output format

`report.json` is the only source for both deliverables, so the sections stay identical across them and comparable between weeks.

## Schema

```json
{
  "start_date": "2026-08-02",
  "end_date": "2026-08-09",
  "summary": "Two or three sentences: sources read, candidate count, and the single most valuable finding of the week.",
  "target": "",
  "health": "One line per feed that failed or moved, with the corrected feeds.json entry when known.",
  "issue": 12,
  "proposals": [
    {
      "title": "short name for the change",
      "score": "high",
      "source": "newsletter, issue date",
      "source_url": "https://...",
      "what": "one or two sentences on the finding",
      "why": "the concrete gap in the target's current configuration",
      "file": "the target file the change touches",
      "diff": "the exact edit as a unified diff"
    }
  ],
  "radar": [
    {
      "name": "...",
      "url": "https://...",
      "note": "what it is and its concrete use in the target, or why it could reshape how it is built"
    }
  ],
  "noted": ["one line per evaluated near-miss still worth a glance"]
}
```

## Field rules

- Name the target repository in `summary` when the run targeted a repository other than the default.
- Set `target` only when the run targeted a repository other than the default, since it is appended to the apply command.
- Set `health` to `All sources healthy.` when nothing failed.
- Rank `proposals` strongest first; they are numbered automatically, and `score` is `high`, `medium`, or `low`.
- Keep `radar` to five entries at most, ranked by impact, and `noted` as plain strings, one per near-miss worth a glance.
- Leave a list empty rather than inventing filler. The fallback lines live in the templates, so an empty week still reads correctly.
- Add `issue` only once `scripts/issue.py` has resolved it; it stays absent when there is no ledger.
- `scripts/render.py` derives the title, the score colors, and the apply command from these fields.

## Subject line

- Compose the subject as `Weekly digest #<issue>: <topics>`.
- Name the week's top two or three findings in `<topics>`, a few words each, proposals before radar.
- Keep the whole subject under about 75 characters so inboxes show it untruncated.
- Use `quiet week` as the topic on an empty week.
- Never change the `Weekly digest` prefix: step 6 and apply mode use it to find past issues.

## Radar bar

- Keep a library with a clear job in the target's stack, such as a faster drop-in for a listed dependency or an audit CLI for a framework in use.
- Keep a technology whose adoption would plausibly change how the target is built.
- Discard hype without a working release, and solid releases with no plausible use in the target.
