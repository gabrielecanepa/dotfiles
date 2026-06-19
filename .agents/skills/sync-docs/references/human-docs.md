# Human-facing docs quality

The bar for README, CONTRIBUTING, docs/, and other docs written for people. Use
it in Phase 2, and remember the Phase 3 split: fix factual drift in human docs
automatically, but treat structural or editorial rewrites as the user's
decision (selectable options). Don't rewrite human prose on assumption.

## The README / AGENTS.md split

The single most common problem: agent instructions leaking into the README, or
human onboarding buried under agent context. Keep them separate.

- **README is for humans** — what the project is, quick start, how to run it,
  how to contribute, where to look next. Concise and focused on a person landing
  on the repo for the first time.
- **AGENTS.md is for agents** — build/test specifics, conventions, gotchas, the
  detailed operational context a contributor doesn't need up front.

If the README carries heavy agent-only instruction, propose moving it to
AGENTS.md. If onboarding basics live only in AGENTS.md, propose surfacing them
in the README. Cross-link rather than duplicate.

## The four axes, for human docs

- **Current** — the most damaging failure. Verify against the repo, not the
  prose: install/run commands actually work, package scripts named exist,
  versions and prerequisites are right, links resolve, the described structure
  matches the tree, screenshots/examples aren't stale. Drift here erodes trust
  in the whole doc.
- **Concise** — respect the reader's time. Lead with what they need; cut
  ceremony, redundant preamble, and walls of prose. Bullets and short sections
  over long paragraphs.
- **Exhaustive** — but complete. A reader should be able to go from zero to
  running, and from interested to contributing, without leaving the docs for
  tribal knowledge. Conciseness must not drop a load-bearing step.
- **Coherent** — consistent voice, terminology, and formatting across docs.
  Match the project's existing tone; don't impose a new one.

## Common findings

- Quick-start commands that no longer match `package.json` / the toolchain.
- A features or API section describing code that changed.
- Missing CONTRIBUTING basics (how to set up, branch, commit, open a PR) when
  the repo clearly takes contributions.
- Dead links, moved paths, renamed scripts.
- Duplicated content that now disagrees with itself across files.
- Generated files (changelogs, API docs) edited by hand and out of sync with
  their generator's config.

## Handling changes (per-document)

Split human-doc changes by kind:

- **Factual drift → fix automatically.** A command that no longer works, a dead
  link, a moved path, a renamed script — these are just wrong. Correct them
  directly; there's no decision to make.
- **Structural / editorial rewrites → ask.** Restructuring, retightening, or
  fleshing out human-authored prose is the author's call. Surface it as a
  decision with selectable options — e.g. _leave as-is_ vs. _expand the thin
  quickstart_ — with a recommended default. Don't rewrite a person's prose on
  assumption.

Default to the lightest touch that fixes the real problem. A factual correction
never justifies a rewrite, and a rewrite of human-authored prose is a bigger
imposition than editing an agentic file — so reach for it only when the doc is
genuinely failing its reader, and only with the user's say-so. Minor optional
polish that isn't worth a question belongs in the recap as a follow-up
suggestion, not as a blocking decision.
