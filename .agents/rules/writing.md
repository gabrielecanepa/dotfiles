---
description: "Use when producing human-facing prose: docs, READMEs, essays, marketing or UI copy, release notes, PR and issue descriptions, emails. Enforces the humanizer skill and bans AI-writing tells."
applyTo: "**/*.markdown,**/*.md,**/*.mdc,**/*.mdx,**/*.rst,**/*.txt,**/README*,**/docs/**"
paths:
  - "**/*.markdown"
  - "**/*.md"
  - "**/*.mdc"
  - "**/*.mdx"
  - "**/*.rst"
  - "**/*.txt"
  - "**/README*"
  - "**/docs/**"
---

# Writing and prose

Applies to substantial human-facing prose in files, chat, PR, issue, and release descriptions, and UI copy.

## Scope

- Skip the humanizer voice treatment for code, code comments, terse factual chat answers, and commit subjects.
- Skip it for pure technical reference where neutral plain text is the correct voice, including instruction and config docs like this one.
- The dash ban has no skip: it covers every committed file, reference docs included.

## Humanizer skill

- Run the `humanizer` skill on any prose longer than a few sentences that a person reads as writing.
- That covers docs, READMEs, essays, marketing copy, announcements, release notes, and long PR descriptions.
- For shorter prose, apply the baseline below inline without the full skill loop.
- The skill loop is draft, then audit ("what still makes this read as AI?"), then final.
- Before returning file content, scan it for em and en dashes; any hit means it is not done.
- The humanizer's voice-matching guidance never overrides committed-file restrictions.
- To audit a repository's existing human docs (README, CONTRIBUTING, CHANGELOG, guides), run `/sync-docs`.

## Baseline rules

- Never write an em or en dash into any committed file, these rule and config docs included.
- Replace a dash with a period, comma, colon, hyphen, parentheses, or a rewrite; live chat output is the only exception.
- Never hard-wrap committed markdown: write each paragraph and list item as one physical line and let editors soft-wrap.
- Follow a project's declared wrap convention only where one exists; code and its comments keep the language's own wrapping.
- Cut promotional inflation: "stands as a testament", "pivotal moment", "rich tapestry", "vibrant", "nestled in the heart of", "showcases", "underscores".
- Prefer `is`, `are`, and `has` over copula avoidance ("serves as", "boasts", "represents a").
- Cut rule-of-three padding, false ranges ("from X to Y"), synonym cycling, negative parallelisms ("not just X, it's Y"), and tailing negations.
- Cut AI vocabulary and filler: delve, leverage, crucial, seamless, "in order to", "it is important to note", excessive hedging.

## Voice and mechanics

- Cut collaborative artifacts ("Great question!", "I hope this helps", "Let me know") and signposting ("Let's dive in", "Here's what you need to know").
- Use sentence-case headings, straight quotes, no decorative emoji, and no mechanical boldface or inline-header bullet lists.
- Write in active voice with specific detail and varied sentence length.
- Add opinion or voice only for essays and personal writing; reference, technical, and legal text stays neutral and plain.

## Do not over-correct

- Edit for clusters of tells, not isolated ones.
- A lone "however", a single curly quote, formal vocabulary, or polished grammar is not evidence of AI.
- Preserve specific detail, dated references, genuine asides, and earned voice.
- Read the skill's "What NOT to flag" section before gutting legitimate prose.
