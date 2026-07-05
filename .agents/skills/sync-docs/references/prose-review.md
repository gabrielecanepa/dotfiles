# Human-doc review

The rubric for reviewing a repository's human-facing documentation. Loaded in
Phase 2 of sync-docs.

## Contents

- [What a human doc is for](#what-a-human-doc-is-for)
- [Currency checks](#currency-checks): verifying each claim against the repo
- [Coherence and structure](#coherence-and-structure)
- [Signal-density checks](#signal-density-checks-what-to-cut)
- [Writing-voice baseline](#writing-voice-baseline)
- [Constraint compliance](#constraint-compliance)

## What a human doc is for

Human docs describe the project to a person: what it is, how to install it, how
to use it, how to contribute, what changed. They complement the agentic docs
(AGENTS.md and friends), which carry the agent-specific context that would
clutter a README. The split is the reason the README-carrying-agent-instructions
finding matters: agent-only walls of text buried in a human doc are in the wrong
place and should move to AGENTS.md.

Map every doc to a role. A doc with no clear role, or one that duplicates
another, is a finding.

- **README**: the front door. What the project is, why it exists, install, a
  minimal working example, and links onward. It should orient a newcomer in the
  first screen and not try to be the full manual. It may live at the repo root
  or at `.github/README.md` (GitHub renders the `.github/` copy first); wherever
  it sits, it plays this role.
- **CONTRIBUTING**: how to set up a dev environment, run tests, and submit
  changes. Its commands are the ones most likely to have drifted, because they
  track the toolchain.
- **CHANGELOG**: version-scoped by nature. Diff-anchored writing is _correct_
  here (see the voice baseline). Check format consistency, not narrative voice.
- **docs/ guides and tutorials**: task-oriented prose. Each should have a clear
  scope, working steps, and current snippets.
- **API / reference prose**: neutral and plain is the right voice. Check it
  matches the actual exported surface; don't inject personality.
- **Templates** (issue, PR, discussion): short contributor-facing prose. Check
  they reference real labels, checks, and process.
- **Package READMEs** (monorepo): nearest wins. Each holds what's specific to its
  package; a package README that just repeats the root is redundancy to flag.

## Currency checks

This is the load-bearing work. A doc's factual claims must match the repo,
because a reader executes them. For each claim type, resolve it against reality
rather than trusting the prose:

- **Install / setup commands**: check the package manager and command match the
  repo (a `pnpm-lock.yaml` means `npm install` in the README is wrong; a
  `yarn.lock` means `pnpm` is wrong). Check named scripts exist
  (`package.json` `scripts`, `Makefile` targets, `pyproject.toml`
  `[tool.*]`/`[project.scripts]`, `Cargo.toml`, a `justfile`/`Taskfile`). Where
  running is cheap and side-effect-free, run it to confirm it works.
- **Usage / build / test commands**: same. A stale `npm run build` or
  `pytest tests/` that no longer exists is worse than none; the reader hits an
  error on the first step and distrusts the rest.
- **Internal links and anchors**: resolve every relative link to a file that
  exists, and every `#anchor` to a real heading in the target. Broken internal
  links are a pure auto-fix once you know the correct target.
- **External links**: check for obvious rot (a link to a moved repo, a
  renamed org, a dead domain) but don't fetch every URL on a healthy doc. When a
  finding hinges on whether an external URL is dead, verify that one; otherwise
  flag questionable ones as follow-ups.
- **Badges**: the shield's target and label must match reality (a CI badge
  pointing at a renamed workflow, a version badge behind the published version, a
  coverage badge for a removed service).
- **Code snippets**: the imports, function names, options, and API shape they
  show must still exist. A snippet importing a renamed module or calling a
  removed method is stale.
- **Versions and supported runtimes**: "requires Node 18+", a supported-Python
  matrix, "compatible with React 17" claims check against the `engines` field,
  the CI matrix, the lockfile, or the dependency ranges.
- **Directory / architecture descriptions**: a "project layout" tree or "how
  it's organized" section must match the actual directory structure.
- **Screenshots / diagrams**: flag ones that clearly show an old UI or an
  outdated architecture as a follow-up (you usually can't regenerate them).

When prose and repo disagree, the repo is the source of truth and the prose is
stale: fix the doc. The one exception is when the _code_ looks wrong and the doc
looks right, which is a code bug, not a docs bug. Flag that as a follow-up for
the user; never change code from a docs sync.

## Coherence and structure

The judgment calls. For each, the question is whether the current arrangement
serves a reader.

- **Orientation.** Does the README's first screen tell a newcomer what this is
  and how to start? A README that opens with deep internals or a wall of badges
  before saying what the project does is misordered.
- **Does each doc earn its place?** Purpose, audience, unique content. A doc that
  duplicates another, that no one links to, or that a generated reference already
  covers is a candidate for merge or removal.
- **Grouping and splitting.** Related guidance together, unrelated apart. A
  README that has swollen into a full manual should split, with the deep content
  moved to `docs/` and linked. A topic fragmented across three half-docs should
  merge.
- **Progressive disclosure.** The README is the entry point and should stay
  scannable; depth belongs in `docs/` loaded on demand. Flag a README that tries
  to hold everything.
- **Navigation.** In a `docs/` tree, is there a way to find things (an index, a
  table of contents, a sidebar config that matches the actual files)? A guide
  that exists but nothing links to is effectively invisible.
- **Coverage.** Is anything a reader needs missing: install, a quick start that
  actually works, the real usage, a config reference, where to get help,
  contribution basics? A gap is as much a finding as bloat.

## Signal-density checks (what to cut)

Padding costs the reader time and buries the real content. Bias toward cutting:

- **Restated headings and warm-up lines.** A heading followed by a sentence that
  just restates the heading before the real content starts. Cut the warm-up.
- **Duplicated instructions.** The same install or setup steps repeated in the
  README and CONTRIBUTING and a `docs/` page. Keep one canonical copy and link to
  it.
- **Generic filler.** "This project aims to provide a robust solution", "best
  practices", boilerplate that says nothing project-specific. Cut or replace with
  the concrete, local fact.
- **Obvious-from-the-repo narration.** A "technologies used" list that just names
  every dependency in `package.json`, or a file-by-file tour of an obvious
  layout, adds nothing unless there's a non-obvious twist.
- **Padded conclusions.** "In conclusion, this project represents an exciting
  step forward" and other generic upbeat endings. Cut them.
- **Stale scaffolding.** Template placeholders never filled in
  (`TODO: describe your project`, `<your-name-here>`), instructions for tooling
  the project no longer uses, a "coming soon" that never came.

The test for keeping a line: would a reader be worse off without it? If not, cut
it.

## Writing-voice baseline

Human docs are read as writing, so AI-writing tells are defects. When the
`humanizer` skill is available, route substantive prose through it (it carries
the full catalog and enforces the dash ban). This baseline is what to apply
inline when `humanizer` is absent, and what to check for regardless.

**The hard rule, enforced everywhere:**

- **No em or en dashes** (`—`, `–`), and no `--` or a space-padded hyphen used in their
  place. Replace each, in rough order of preference: a period (new sentence), a
  comma (tight aside), a colon (introducing an explanation), parentheses (a true
  aside), or restructure. This is a hard constraint. Before finishing any file
  you edited, scan it for `—` and `–`; any hit means it isn't done.

**The rest of the baseline** (the same tells the `humanizer` skill catalogs;
edit for clusters, not isolated hits):

- No significance or promotional inflation: "stands as a testament", "pivotal
  moment", "rich tapestry", "vibrant", "nestled in the heart of", "showcases",
  "underscores", "boasts", "breathtaking", "must-have".
- Prefer `is`/`are`/`has` over copula avoidance: "serves as", "boasts",
  "represents a", "stands as".
- No rule-of-three padding, no false ranges ("from X to Y" where X and Y aren't
  a real scale), no synonym cycling, no negative parallelisms ("not just X, it's
  Y"), no tailing negations ("..., no guessing", "..., no setup required" tacked
  on as a fragment).
- Cut AI-vocabulary filler: delve, leverage, crucial, seamless, robust,
  streamline, "in order to", "it is important to note", "at this point in time",
  excessive hedging ("it could potentially possibly").
- No sycophantic or signposting artifacts: "Great question!", "Let's dive in",
  "Here's what you need to know", "without further ado".
- Mechanics: sentence-case headings (not Title Case), straight quotes (not
  curly), no decorative emoji, no mechanical boldface, no inline-header bullet
  lists (`- **Thing:** restates thing`).
- Prefer active voice and concrete detail. Vary sentence length.

**Where plain and neutral is correct.** Reference docs, API docs, config tables,
CHANGELOGs, and legal text should read as plain technical prose. Don't inject
opinion, first person, or personality there; that's the right human voice for
reference material. Diff-anchored writing ("this replaces the old approach") is a
tell in a normal doc but correct in a CHANGELOG or migration guide, which are
version-scoped by nature.

**Don't over-correct.** A lone "however", a single formal word, one curly quote
from an editor, or polished grammar is not evidence of AI. Preserve specific
detail, genuine asides, dated references, and the author's earned voice. When a
doc is already clean, current, and dash-free, the correct finding is "no change
needed", not a rewrite that flattens a real voice.

## Constraint compliance

Whatever the project declares is the standard to check against. Constraints come
in no fixed format; infer them from the docs and any config, and honor them as
written:

- **Declared style guides**: a `CONTRIBUTING` section on docs, a `STYLE` /
  `STYLEGUIDE` file, a docs README's own conventions. Section order, heading
  style, voice, terminology.
- **Docs linters**: `.markdownlint*`, `.vale.ini` / `.vale/`, `.textlintrc`,
  `.remarkrc`, a `cspell` config. These encode the project's rules
  mechanically. Honor them, and prefer running the linter to hand-checking what
  it covers. A doc that fails the project's own linter is a compliance finding.
- **Length or line-width caps**: some projects cap README length or wrap prose at
  a column. Respect the declared cap.
- **Required sections**: a project may require every `docs/` page to have a
  frontmatter block, a title, or a "See also" footer. Check conformance.
- **Terminology and casing**: a project may standardize product names, casing
  (`JavaScript` not `Javascript`), or banned words. Apply the project's list.

Report compliance as concrete pass/fail items so the proposal shows exactly
what's off and what fixing it costs.
