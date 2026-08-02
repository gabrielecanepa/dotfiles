---
name: sync-docs
description: >-
  Audit and repair human-facing repository docs against the code. Use for
  /sync-docs or requests to review README, CONTRIBUTING, CHANGELOG, guides, or
  docs; excludes agentic files and supports --check.
---

# sync-docs

Keep a repository's **human-facing documentation** honest: current against the code, coherent for a reader, and written in a clean human voice free of AI tells. This skill scans every human doc in scope, checks each claim against the actual repo, finds drift, dead links, and slop, fixes what's unambiguous, and stops to ask only when a real editorial decision is the user's.

Agentic docs (AGENTS.md and nested variants, CLAUDE.md and other tool entrypoints, the `.agents/` and `.claude/` trees, rules, skills, MCP config) are explicitly out of scope. Do not read them for editing, do not touch them. The sibling `sync-agents` skill owns that surface. The one place the two meet is the README-vs-AGENTS.md boundary in Phase 2, and even there you only propose moving agent-only content out, you never rewrite the agentic file.

## Arguments

The invocation may carry two things, both optional. Parse them from the prompt before Phase 0.

- **A scope path or area** (e.g. `/sync-docs the docs folder`, `/sync-docs README.md`). Present → narrow the sweep to that file or subtree and lead there, but still do a light baseline pass over the rest of the human docs so nothing silently rots. Absent → audit **all** human docs in the resolved root.
- **`--check`** → audit only. Produce the findings and the recap, apply **no** edits and remove nothing. This is the read-only inversion of the default.

## Operating contract

Hold these for the whole run.

- **Act on the clear wins; ask only for real decisions.** Apply every fix with a single best answer: a wrong command, a dead link, a renamed script the README still calls, a section describing a feature that no longer exists, a dash the writing rules ban. Stop only where the call is genuinely editorial (a rewrite that changes meaning or tone, cutting a section that might still be wanted, restructuring a guide), and put it as selectable options. Don't ask about the obvious; don't unilaterally rewrite the author's voice. Under `--check`, apply nothing: report both the clear fixes you would make and the decisions you'd raise.
- **Verify every claim against the repo; the code is the source of truth.** A doc describes the project as it actually is, so check each factual claim (install command, script name, config key, file path, code snippet, badge target, supported version, directory layout) against the real repo. When prose and repo disagree the prose is stale: fix the doc to match. Drift is the most common and most damaging failure, because a reader runs what the README lists. Flag the reverse (code looks wrong, doc looks right) as a follow-up; never change code from inside a docs sync.
- **Honor the project's declared voice; don't impose your own.** If the repo states a doc style (a tone, a heading convention, a structure, a banned-word list, a length cap, a required section order), that is the law: infer it from the existing docs and any contributing guide, apply it, flag violations. Where the repo declares nothing, fall back to the baseline writing rules below, but match the surrounding document's existing voice rather than flattening it.
- **Bias to clarity and signal, not word count.** Padding, restated headings, generic filler, and duplicated instructions cost the reader time and hide the real content. Cut what doesn't earn its place, but never load-bearing context (setup steps, non-obvious gotchas, the actual how-to), and never the original's concrete detail (real commands, version numbers, named tools, genuine asides). Editing for voice keeps the same content in a cleaner voice; it is not a compression pass.
- **Clean human voice is part of correctness.** AI-writing tells (see the writing baseline below) are defects on the same footing as a dead link. The hard one, enforced everywhere: **no em or en dashes.** Route voice work through the `humanizer` skill when available, else apply the baseline inline. Details in Phase 2.
- **Removals must be recoverable.** Auto-remove a doc file only when it's git-tracked, using `git rm` so it stays recoverable. For untracked files or a non-git scope, treat removal as a decision and ask first, or back the file up to a timestamped location before removing. Never a silent hard delete.

## Phase 0: resolve scope

Decide which root you operate on, and say so before touching anything.

1. Get the current directory.
2. Find a project root: run `git rev-parse --show-toplevel` from cwd. If it returns a path that is **not** the home directory, that path is the project root → **project scope**.
3. No git? Walk up from cwd for a project marker (`README.md`, `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`, `docs/`), stopping **before** `~`. First marker found → project root.
4. If cwd is the home directory itself, or no project root is found above `~`, stop and ask: a bare `~` almost never has human project docs to sync, and syncing the whole home directory is not what the user meant.

State the resolved scope and root in one line. If a scope path was given, state it too. Then proceed. If cwd is ambiguous, name the ambiguity and confirm before scanning.

## Phase 1: inventory

Build a manifest of every in-scope human doc. The taxonomy:

- **Community-health docs**: `README*`, `CONTRIBUTING*`, `CHANGELOG*`, `CODE_OF_CONDUCT*`, `SECURITY*`, `SUPPORT*`, `GOVERNANCE*`, `FUNDING*`, `AUTHORS*`, `LICENSE*` (read-only, see below), `INSTALL*`, `USAGE*`, `FAQ*`, and any other `*.md`/`*.rst`/`*.txt` at the repo root clearly written for a person. **Look for these in `.github/` too, not just the root.** GitHub resolves each community-health file (README, CONTRIBUTING, SECURITY, SUPPORT, CODE_OF_CONDUCT, GOVERNANCE, FUNDING) from three locations and renders the first it finds, in the order `.github/` → repo root → `docs/`. A repo whose real front page is `.github/README.md` has no root README at all, so scanning only the root would miss it entirely. Always inventory `.github/` for these files, treat whichever copy GitHub would render as the canonical one, and don't let the leading dot fool you into reading `.github/` as agent config (that's `.agents/`/`.claude/`; the specific agent files that do live in `.github/` are excluded by name below).
- **`docs/` and `doc/` trees**: guides, tutorials, references, how-tos, whatever format the project uses (Markdown, reStructuredText, MDX, AsciiDoc).
- **Site sources**: `website/`, `site/`, docs-generator sources (Docusaurus, MkDocs, Sphinx, VitePress, Astro Starlight, Jekyll `_docs`), and their content directories. Audit the content prose, not the generator config, with one exception: the **nav/index config** that lists pages (a `sidebars.js`, an MkDocs `nav:` block, a Sphinx `toctree`) is in scope as a link-integrity target, because an entry pointing at a renamed or deleted page is the same dead-link drift you fix elsewhere.
- **`.github/` human templates**: `ISSUE_TEMPLATE/*`, `PULL_REQUEST_TEMPLATE*`, `DISCUSSION_TEMPLATE/*`. These are prose a contributor reads.
- **In-repo package docs**: a `README` inside each published package of a monorepo. Nearest-README-wins the same way nested AGENTS.md does: a package README holds what's specific to that package.

Exclude, and never edit:

- **Agentic docs** (the whole `sync-agents` surface): `AGENTS.md` and nested copies, `CLAUDE.md`, `.cursor/`, `.cursorrules`, `GEMINI.md`, `.windsurfrules`, `.clinerules`, `.aider*`, `.github/copilot-instructions.md`, `.github/instructions/*`, the `.agents/` and `.claude/` trees, any `SKILL.md`, rule files, MCP config. If a task spans both surfaces, do the human docs here and hand the agentic side to `sync-agents`.
- **Generated or vendored docs**: API reference emitted by a doc generator (`typedoc`, `jsdoc`, `sphinx-apidoc`, `cargo doc` output), `CHANGELOG` entries produced by a release tool, anything under a build/output dir (`node_modules/`, `dist/`, `_site/`, `site/` build output, `target/doc/`). Editing generated prose is pointless; it regenerates. Flag a stale generated doc as a follow-up (regenerate it) rather than hand-editing.
- **`LICENSE`/`COPYING`**: legal text. Verify it exists and the README's stated license matches it, but never rewrite license wording. A mismatch (README claims a license but no LICENSE file exists, or the two disagree) is a decision to flag, not an edit to make: see Phase 3.
- **Machine-authored data** the docs embed by include or transclusion: fix it at its source, not in the rendered copy.

For each file record path and role. A doc length or line-width cap is rare in human docs (it's mostly an agentic-doc concern); if the repo declares one, measure against it with whatever counter is on hand rather than eyeballing.

Then extract **declared conventions**: read `CONTRIBUTING`, any `docs/` style guide or `STYLE`/`STYLEGUIDE` file, a `.markdownlint*` / `.vale.ini` / `.textlintrc` config, and the existing docs' own patterns for stated rules (heading style, voice, structure, required sections, banned words, line length). Record each as a checkable item for Phase 2. A linter config is a declared constraint: honor it, and prefer running the linter to hand-checking what it covers.

## Phase 2: analyze

Load the rubric now: **[references/prose-review.md](references/prose-review.md)**. It covers the doc taxonomy, currency checks (how to verify each kind of claim against the repo), coherence and structure, the signal-density cuts, the writing-voice baseline, and constraint compliance. Judge every doc on four axes:

1. **Current**: does every claim match the actual code, stack, scripts, config, and structure? Verify against the repo (package scripts, config files, exported API, directory layout, badge and link targets, version numbers), don't trust the prose. This is the load-bearing axis; drift is the failure that costs a reader the most.
2. **Coherent**: does the document flow, is it organized so a reader finds what they need, are sections in a sensible order, is anything duplicated across docs, is anything so long it should split or so fragmented it should merge?
3. **Complete**: is anything a reader genuinely needs missing (install, quick start, the actual usage, config reference, a link to deeper docs)? Gaps are as much a finding as bloat. Conciseness never wins by dropping load-bearing how-to.
4. **Clean voice + compliant**: is it free of AI-writing tells, does it pass the dash ban, and does it honor every style convention the repo declared?

**Verifying currency** is the load-bearing work and the reference spells out how per claim type. The short version: run or resolve what the doc asserts. Install and build commands → check they exist in the manifest (`package.json` scripts, `Makefile` targets, `pyproject.toml`) and, where cheap and safe, that they run. Links → resolve internal links to real files and anchors; check external links are not obviously dead (flag, don't over-fetch). Code snippets → check APIs and imports they show still exist. Badges → check the target still matches. Versions and supported-runtime claims → check against the lockfile, CI matrix, or engines field.

**One boundary check that touches an agentic file** but is a human-docs concern: **does the README carry heavy agent-only instruction** (a wall of "instructions for Claude/Cursor" that belongs in AGENTS.md)? If so, flag it as a finding and propose moving it into the agentic surface (a `sync-agents` follow-up). This is the only reason to look at AGENTS.md, and you propose the move, you don't perform the agentic edit here.

**The writing-voice pass.** Human docs are read as writing, so a clean voice is correctness, not polish. Handle it in this order:

- **Prefer the `humanizer` skill when it's available.** It's invoked by the name `humanizer` (installed from source `blader/humanizer`); check whether that skill is present. If it is, route substantive prose (anything longer than a few sentences that a person reads as writing: README bodies, guide and tutorial prose, long CONTRIBUTING sections, release-note narrative) through its draft → audit → final loop. It covers the full AI-tell catalog and enforces the dash ban. Feed it the section, take back the cleaned prose, and slot it in.
- **When `humanizer` is absent, apply the baseline inline.** Don't block on the skill. The one non-negotiable, load-bearing every time: **no em or en dashes** (`—`, `–`), and no `--` or a space-padded hyphen standing in for one. Replace each with a period, comma, colon, parentheses, or a rewrite. Before finishing any file you edited, scan it for `—` and `–`; any hit means it isn't done. The rest of the baseline (inflation, copula avoidance, rule-of-three, AI-vocabulary filler, sycophancy and signposting, mechanics: sentence-case headings, straight quotes, no decorative emoji or mechanical boldface) is enumerated in the reference's writing-voice section; apply it from there.
- **Don't over-correct.** Edit for clusters of tells, not isolated ones. A lone "however", a single formal word, or one curly quote from an editor is not evidence of AI. Preserve specific detail, genuine asides, dated references, and the author's earned voice. Reference docs and technical prose are correctly neutral and plain; don't inject personality there. A README that is already clean, current, and dash-free needs no rewrite, and saying so is a valid finding.

**Research only on a real knowledge gap.** When a finding depends on an external fact you can't confirm from the repo (whether an external URL is actually dead, whether a documented third-party command changed its flags), check it rather than guessing. Don't open-endedly rewrite a healthy doc.

Produce a synthesized findings list: each item is a concrete problem with its location and why it matters. Don't show a stream of consciousness.

## Phase 3: apply (default) or report (`--check`)

Work through the findings. For each, make one call: single best answer, or the user's to decide?

Under **`--check`**, apply nothing. List what you would auto-apply and what you'd raise as a decision, then jump to Phase 4. Everything below describes the default (apply) path.

**Apply automatically** when the fix is unambiguous and low-risk. Make the edit directly, matching the document's existing voice and structure:

- factual drift (wrong or renamed command, dead internal link, stale path, wrong config key, outdated version number, a badge pointing at a moved target, a snippet using a removed API),
- writing-voice fixes with one clear resolution: remove every em/en dash, strip decorative emoji, fix Title Case headings to sentence case, straighten curly quotes, cut a clear filler phrase or a restated-heading warm-up line,
- removing a git-tracked doc that is dead or a zero-content duplicate, via `git rm`, so it stays recoverable,
- cutting obvious bloat (a padded "Conclusion", a duplicated install section that a canonical one already covers).

For a substantive prose rewrite (a whole section written in heavy AI voice, a README intro full of inflation), the _cleanup itself_ is a clear win, but do it carefully: run it through `humanizer` if available, keep all the original's content and specifics, and match the document's voice. If a rewrite would change the doc's meaning or drop information you can't confirm is safe to drop, that's a decision, not an auto-fix.

Don't narrate each edit as you go; account for them all in the recap.

**Stop and ask**, as selectable options, when the call is genuinely the user's:

- two or more reasonable solutions with real tradeoffs (restructure a guide vs. leave it; consolidate two overlapping docs vs. keep both with clearer scope; which of two near-duplicate docs becomes canonical),
- intent you can't verify (a section describing a feature you can't find in the code, which may be planned, deprecated-but-documented on purpose, or genuinely stale; content that might be load-bearing for a reader you can't see),
- a rewrite that changes meaning, cuts information, or overrides an authorial choice you can't confirm is wrong,
- a legal or license claim. Correcting the _mechanics_ around it is fine (a broken link to a LICENSE that does exist, a typo). But changing which license is stated, or dropping a license claim because the LICENSE file is missing, is the author's call with legal weight: flag the mismatch (README says MIT, no LICENSE file present) and let them resolve it, rather than editing the claim or inventing the file,
- any removal that wouldn't be git-recoverable (untracked file, or a non-git scope).

Pose each as a plain question with concrete options and a recommended default, using the host's question mechanism. Keep resolving everything else while a decision waits; only block when applying the rest genuinely depends on the answer.

After editing, if the repo has a docs linter or link checker (`markdownlint`, `vale`, `textlint`, a `lychee`/link-check CI step) and it's cheap to run, run it on the files you touched and fix failures your changes caused. If a doc includes a runnable snippet the project tests (doctests, `mdx` examples, a `test-examples` script), run that. Never commit or push automatically; the commit boundary is the user's.

## Phase 4: recap

Close with a scannable record. Lead with a one-line verdict, then:

- **Scope**: the resolved root, the scope path if any, and mode (applied / `--check` audit).
- **Changed**: what you applied, one line each with the why. Under `--check`, retitle this **Would change** and list the fixes you'd make instead.
- **Decisions pending** _(if any)_: the questions you raised and their options, so an unanswered one stays visible.
- **Follow-ups** _(if any)_: anything only the user can do or that belongs elsewhere (a `sync-agents` handoff for agent content found in the README, a generated doc that needs regenerating, a code-looks-wrong flag, an external link you couldn't verify).

If everything was unambiguous and applied, the recap is just the verdict and the change list. No ceremony. When work is commit-worthy, offer a Conventional Commit message and leave the commit to the user.

## Bundled resources

- [references/prose-review.md](references/prose-review.md): the human-doc review rubric: taxonomy, per-claim currency checks, coherence, signal-density cuts, the writing-voice baseline, and constraint compliance. Loaded in Phase 2.
