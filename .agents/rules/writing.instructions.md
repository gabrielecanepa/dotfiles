---
description: 'Use when producing human-facing prose — docs, READMEs, comments-as-prose, blog/essays, marketing or UI copy, release notes, PR/issue descriptions, emails. Enforces the humanizer skill and bans the common AI-writing tells. Not for code, terse chat, or commit subjects.'
applyTo: '**/*.markdown,**/*.md,**/*.mdc,**/*.mdx,**/*.rst,**/*.txt,**/README*,**/docs/**'
paths:
  - '**/*.markdown'
  - '**/*.md'
  - '**/*.mdc'
  - '**/*.mdx'
  - '**/*.rst'
  - '**/*.txt'
  - '**/README*'
  - '**/docs/**'
---

# Writing & Prose

Applies to any substantial human-facing prose you produce — in files **and** in chat, PR/issue/release descriptions, and UI copy. Skip for: code and code comments, terse factual chat answers, conventional-commit subject lines, and pure technical reference where neutral plain text already _is_ the correct human voice — including instruction/config docs like these rule files, which are reference and may use dashes freely.

## When to invoke the `humanizer` skill

Run the **`humanizer`** skill (source: `blader/humanizer`) on any prose longer than a few sentences that a person will read as writing: docs, READMEs, essays/blog posts, landing/marketing copy, announcements, release notes, long PR descriptions. For shorter prose, apply the baseline below inline without the full skill loop.

The skill's loop is **draft → audit ("what still makes this read as AI?") → final**. Before returning the final text, scan it for `—` and `–`; any hit means it isn't done.

## Baseline rules (apply even without invoking the skill)

- **No em or en dashes** in final prose. Replace with a period, comma, colon, parentheses, or a rewrite. This is a hard constraint, not a "use sparingly".
- **No significance/promotional inflation**: drop "stands as a testament", "pivotal moment", "rich tapestry", "vibrant", "nestled in the heart of", "showcases", "underscores".
- **Prefer `is`/`are`/`has`** over copula avoidance ("serves as", "boasts", "represents a").
- **No rule-of-three padding**, no false ranges ("from X to Y"), no synonym cycling, no negative parallelisms ("not just X, it's Y") or tailing negations ("…, no guessing").
- **Cut AI-vocabulary clusters and filler**: delve, leverage, crucial, seamless, "in order to", "it is important to note", excessive hedging.
- **No collaborative/sycophantic artifacts** ("Great question!", "I hope this helps", "Let me know…") and **no signposting** ("Let's dive in", "Here's what you need to know") — just say the thing.
- **Mechanics**: sentence-case headings (not Title Case), straight quotes (not curly), no decorative emoji, no mechanical boldface or inline-header bullet lists.
- **Active voice, specific detail, varied sentence length.** Add opinion/voice only for essays and personal writing; for reference/technical/legal text, neutral and plain is correct — don't inject personality there.

## Don't over-correct

Edit for **clusters** of tells, not isolated ones. A lone "however", a single curly quote, formal vocabulary, or polished grammar is not evidence of AI — preserve specific detail, dated references, genuine asides, and earned voice. See the skill's "What NOT to flag" section before gutting legitimate prose.
