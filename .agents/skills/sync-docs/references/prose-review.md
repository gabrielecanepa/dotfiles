# Human-doc review

The rubric for reviewing a repository's human-facing documentation. Loaded in Phase 2 of sync-docs.

## Contents

- [Doc roles](#doc-roles)
- [Currency: commands and links](#currency-commands-and-links)
- [Currency: code and structure](#currency-code-and-structure)
- [Coherence and structure](#coherence-and-structure)
- [Signal density](#signal-density)
- [Writing voice](#writing-voice)
- [Constraint compliance](#constraint-compliance)

## Doc roles

Human docs tell a person what the project is, how to install it, how to use it, how to contribute, and what changed.

Agentic docs carry the agent-specific context instead, which is why an agent-only wall of text inside a README belongs in `AGENTS.md`.

Map every doc to one role. A doc with no clear role, or one that duplicates another, is a finding.

- README is the front door: what the project is, why it exists, install, a minimal working example, and links onward.
- Judge a README on its first screen, not on completeness; `.github/README.md` holds the same role and GitHub renders it first.
- CONTRIBUTING covers dev setup, running tests, and submitting changes; its commands drift first because they track the toolchain.
- CHANGELOG is version-scoped, so check format consistency and not narrative voice; diff-anchored writing is correct here.
- A `docs/` guide or tutorial is task-oriented, so check it has a clear scope, working steps, and current snippets.
- API and reference prose stays neutral and plain; check it matches the exported surface and inject no personality.
- An issue, PR, or discussion template is short contributor prose; check it names real labels, checks, and process.
- In a monorepo the nearest package README wins; one that repeats the root README is redundancy to flag.

## Currency: commands and links

This is the load-bearing work. A reader executes the claims, so resolve each against the repo instead of trusting the prose.

- Check the install command against the lockfile: `pnpm-lock.yaml` makes `npm install` wrong, `yarn.lock` makes `pnpm` wrong.
- Check every named script exists in `package.json` scripts, a `Makefile`, `pyproject.toml`, `Cargo.toml`, a `justfile`, or a `Taskfile`.
- When running a documented command is cheap and side-effect-free, run it to confirm it works.
- Check usage, build, and test commands the same way; a stale first step makes the reader distrust the whole doc.
- Resolve every relative link to a file that exists and every `#anchor` to a real heading in the target file.
- Fix a broken internal link outright once the correct target is known.
- Check external links for obvious rot such as a moved repo, a renamed org, or a dead domain.
- When a finding hinges on whether an external URL is dead, verify that one URL and flag the rest as follow-ups.

## Currency: code and structure

- Check each badge target and label against reality, starting with a CI badge pointing at a renamed workflow.
- Flag a version badge behind the published version and a coverage badge for a removed service.
- Check every snippet's imports, function names, options, and API shape still exist; a renamed module or removed method is stale.
- Check runtime claims such as "requires Node 18+" or a supported-Python matrix against `engines` and the dependency ranges.
- Cross-check the same claims against the CI matrix and the lockfile when `engines` is absent.
- Check a project-layout tree or an "how it is organized" section against the actual directory structure.
- Flag a screenshot or diagram showing an old UI or architecture as a follow-up, because you usually cannot regenerate it.

When prose and the repo disagree, the repo is the source of truth: the prose is stale, so fix the doc.

The one exception is code that looks wrong against a doc that looks right. That is a code bug: flag it as a follow-up and never change code from a docs sync.

## Coherence and structure

These are the judgment calls. For each one, ask whether the current arrangement serves a reader.

- Check the README's first screen tells a newcomer what this is and how to start; internals or a badge wall first is misordered.
- Check each doc earns its place through purpose, audience, and unique content, and propose a merge or a removal when it does not.
- Flag a doc that duplicates another, that nothing links to, or that a generated reference already covers.
- Keep related guidance together and unrelated guidance apart: split a README swollen into a manual, merge a topic fragmented across half-docs.
- Move depth out of the README into `docs/` and link it, so the entry point stays scannable.
- Check a `docs/` tree has a working index, table of contents, or sidebar config that matches the actual files.
- Check coverage of install, a working quick start, the real usage, a config reference, where to get help, and contribution basics.
- Treat a coverage gap as a finding on the same footing as bloat.

## Signal density

Padding costs the reader time and buries the real content, so bias toward cutting.

- Cut a warm-up line that restates the heading above it before the real content starts.
- Keep one canonical copy of duplicated install or setup steps and link to it from the others.
- Cut generic filler such as "this project aims to provide a robust solution" or "best practices", or replace it with the concrete local fact.
- Cut narration obvious from the repo: a "technologies used" list naming every dependency, or a file-by-file tour of an obvious layout.
- Keep that narration only where it carries a non-obvious twist.
- Cut a padded conclusion such as "in conclusion, this project represents an exciting step forward".
- Cut unfilled template placeholders such as `TODO: describe your project` or `<your-name-here>`.
- Cut instructions for tooling the project no longer uses, and a "coming soon" that never came.

The test for keeping a line: would a reader be worse off without it? If not, cut it.

## Writing voice

Human docs are read as writing, so AI-writing tells are defects.

When the `humanizer` skill is available, route substantive prose through it: it carries the full catalog and enforces the dash ban.

Apply the baseline below inline when `humanizer` is absent, and check for these tells either way.

### The dash ban

- Never write an em dash (U+2014) or an en dash (U+2013), and never use `--` or a space-padded hyphen in their place.
- Replace each one in this order of preference: a period, a comma, a colon, parentheses, or a restructured sentence.
- Before finishing any file you edited, scan it for both code points; any hit means the file is not done.

### Baseline tells

Edit for clusters of tells, not isolated hits.

- Cut promotional inflation: "stands as a testament", "pivotal moment", "rich tapestry", "vibrant", "nestled in the heart of", "showcases".
- Prefer `is`, `are`, and `has` over copula avoidance such as "serves as", "boasts", "represents a", or "stands as".
- Cut rule-of-three padding, false ranges ("from X to Y" over no real scale), synonym cycling, and negative parallelisms.
- Cut tailing negations tacked on as a fragment, such as ", no guessing" or ", no setup required".
- Cut AI vocabulary and filler: delve, leverage, crucial, seamless, robust, streamline, "in order to", "it is important to note", hedging.
- Cut sycophantic and signposting artifacts: "Great question!", "Let's dive in", "Here's what you need to know", "without further ado".
- Fix mechanics: sentence-case headings, straight quotes, no decorative emoji, no mechanical boldface, no inline-header bullet lists.
- Prefer active voice with concrete detail, and vary sentence length.

### Where plain is correct

- Keep reference docs, API docs, config tables, CHANGELOGs, and legal text as plain technical prose.
- Add no opinion, first person, or personality there; plain is the right human voice for reference material.
- Treat diff-anchored writing ("this replaces the old approach") as correct in a CHANGELOG or migration guide and as a tell elsewhere.

### Do not over-correct

- Treat a lone "however", a single formal word, one curly quote, or polished grammar as no evidence of AI.
- Preserve specific detail, genuine asides, dated references, and the author's earned voice.
- When a doc is already clean, current, and dash-free, report "no change needed" rather than a rewrite that flattens a real voice.

## Constraint compliance

Whatever the project declares is the standard to check against.

Constraints come in no fixed format, so infer them from the docs and any config, and honor them as written.

- Apply a declared style guide from a `CONTRIBUTING` docs section, a `STYLE` or `STYLEGUIDE` file, or a docs README's own conventions.
- Check section order, heading style, voice, and terminology against that guide.
- Honor docs linters (`.markdownlint*`, `.vale.ini` or `.vale/`, `.textlintrc`, `.remarkrc`, a `cspell` config) and prefer running them to hand-checking.
- Treat a doc that fails the project's own linter as a compliance finding.
- Respect a declared length or line-width cap, and measure it with a counter rather than by eye.
- Check the sections a project requires on every `docs/` page, such as a frontmatter block, a title, or a "See also" footer.
- Apply the project's terminology and casing list, such as `JavaScript` and not `Javascript`, plus its banned words.
- Report compliance as concrete pass or fail items, so the proposal shows exactly what is off and what fixing it costs.
