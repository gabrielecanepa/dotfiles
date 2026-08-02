---
description: 'Code work: scope, diffs, verification, and commit safety.'
applyTo: '**'
---

# Engineering guidelines

## Before coding

- Apply precedence: user, repository, this rule, existing style. Define success and assumptions.
- Prefer no change, standard library, native feature, installed dependency, then new code; check official documentation for uncertain APIs.
- Use the safest reversible interpretation. Stop before destructive, irreversible, production, or secret-changing actions.
- Review, inspect, analyze, diagnose, and assess are read-only asks: they authorize reading and reporting, not edits, autofixes, branch switches, stash, reset, or clean. Check `git status --short --branch -uall` first and leave modified, staged, and untracked files as they are. Writing needs authorization in the current turn.
- Delegate bounded independent tasks or required reviews. Default to read-only, non-nested, with max three concurrent agents. Primary owns writes, architecture, synthesis, and verification. Parallel writers require permission, isolated worktrees, and disjoint files.
- Give agents root, scope, evidence, and stop conditions; wait before synthesis. Use configured explorers and reviewers. Specify provider, model, effort, and sandbox in definitions.

## Minimum correct code

- Build only what is required. Avoid speculative abstractions, options, compatibility layers, and duplicated logic.
- Search shared layers before adding helpers, constants, hooks, or tokens. Import matches; promote only for a second consumer and update the first. Retyped constants, handlers, and flows are duplicates.
- Use types for impossible states. Guard I/O, concurrency, timeouts, cancellation, hydration, and races. Async UI includes loading, empty, error, and boundary states.
- Add JSDoc only where adjacent code establishes a public API convention, plus needed linter directives and required headers. Prefer clear names and structure; leave no explanatory, section, TODO, or dead comments. A request to make code clear asks for naming and structure, not comments.
- Keep agentic files concrete, scoped, and self-contained. Inline logic unless auth, compiled tooling, or output size prevents it; declare dependencies.
- Split large features into scoped `spec`, `plan`, and `tasks`; never load scratch plans globally. Use `sync-agents` for agentic files and skills.

## Surgical diffs

- Touch only required lines. Renames change identifiers only, not comments or whitespace. Do not refactor or format adjacent code.
- Remove only newly dead code; flag pre-existing dead code. Fix adjacent bugs only when they intersect the change.
- After fixing a class of bug, grep the repository for the same shape and answer for every match: same bug, safe to leave and why, or unsure and ask. Fix the matches that are the same bug; report unrelated bugs the sweep surfaces instead of fixing them here.
- Re-read a file the user edited before continuing on it. Their edits are locked intent: build on their version, and never restore wording or code they removed from an earlier draft of yours.
- Run owners for generated code, lockfiles, route trees, clients, and schemas. Update docs when behavior, commands, paths, or architecture change.

## Verification

- Reproduce bugs, add regression coverage, and establish a green baseline before behavior-preserving refactors.
- Run relevant checks: types, lint, tests, then behavior; detect package manager and runner. Report commands and distinguish new failures from baseline noise.
- Verify UIs with browser automation and screenshots. Follow `browser.instructions.md`; static checks cannot verify layout, interaction, animation, accessibility, or auth.
- After multi-file or behavior changes, use a reviewer subagent for correctness, security, spec compliance, and conventions. Supply the complete diff when its tools cannot read Git history. Findings cite `file:line` and a failure scenario. Confirm them, stop after two rounds, and hand off unresolved items.
- Source, CI, package contents, installed runtime, release assets, registry, and deployed state are separate evidence layers. One never implies another, so report each layer checked and name the rest as gaps before saying released, published, installed, or done.
- Never put secrets in source, command arguments, logs, or commits.

## Commit boundary and handoff

- Never run `git add`, `git commit`, `git push`, or another history-writing command unless the current prompt asks. Implementation is not permission; permission does not carry forward without standing scope.
- For commit-worthy uncommitted work, including "finish up," render exactly:

````markdown
### Changes

- [file:line](path/to/file:line) - describes the resulting behavior.

I suggest this commit message:

```text
type: imperative subject
```

Want me to run the commit?
````

Render the block itself. Never replace it with a description of the block, including when the prompt asks what you would do.

Use the repository's commit convention. Group separate commits into separate change lists and message blocks.
