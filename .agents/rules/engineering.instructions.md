---
description: 'Code work: scope, diffs, verification, and commit safety.'
applyTo: '**'
---

# Engineering

## Before coding

- Apply precedence: user, repository, this rule, existing style. Define success.
- Prefer no changes, standard libraries, native features, installed dependencies, then new code; check the official docs for uncertain APIs.
- Use the safest reversible interpretation. Stop before destructive, irreversible, production, or secret-changing actions.
- Review, inspect, analyze, diagnose, and assess are read-only asks: they authorize reading and reporting, not edits, autofixes, branch switches, stash, reset, or clean. Check `git status --short --branch -uall` first and leave every modified, staged, or untracked file alone. Writing needs authorization in the current turn.
- Delegate bounded independent tasks and required reviews to the configured explorers and reviewers: read-only, non-nested, max 3 concurrent with root, scope, evidence, and stop conditions. The primary owns writes, architecture, synthesis, and verification. Parallel writers require permission, isolated worktrees, and disjoint files.

## Minimum correct code

- Build only what is required. Avoid speculative abstractions, options, compatibility layers, and duplicated logic.
- Search shared layers before adding helpers, constants, hooks, or tokens. Import matches; promote only for a second consumer and update the first. Retyped constants, handlers, and flows are duplicates.
- Use types for impossible states. Guard I/O, concurrency, timeouts, cancellation, hydration, and races. Async UI includes loading, empty, error, and boundary states.
- Leave no explanatories, sections, TODOs, or dead comments; clarity comes from names and structure, never comments. Use JSDoc only where adjacent code establishes a convention or when explicitly requested; needed linter directives and required headers stay.
- Keep agentic files concrete, scoped, and self-contained. Inline logic unless auth, compiled tooling, or output size prevents it; always declare dependencies.

## Surgical diffs

- Touch only required lines. Renames change identifiers only, not comments or whitespace. Do not refactor or format adjacent code.
- Remove only newly dead code; flag pre-existing dead code. Fix adjacent bugs only when they intersect the change.
- After fixing a bug, grep the repository for the same shape and answer for every match: same bug (fix it), safe to leave and why, or unsure (ask). Report unrelated bugs instead of fixing them here.
- Re-read a file the user edited before continuing on it: their edits are locked intent, so build on their version and never restore wording or code they removed from your earlier drafts.
- Never hand-edit generated artifacts (lockfiles, route trees, generated clients, schemas) but regenerate them with their owning tool. Update the docs when behavior, commands, paths, or architecture change.

## Verification

- Reproduce bugs, add regression coverage, and establish a green baseline before behavior-preserving refactors. Run relevant checks (types, lint, tests, then behavior) with the detected package manager and runner; report commands and distinguish new failures from baseline noise.
- Verify UIs with browser automation and screenshots following `browser.instructions.md`, as static checks cannot verify layout, interaction, animation, accessibility, or auth.
- After multi-file or behavior changes, run a reviewer subagent for correctness, security, spec compliance, and conventions, including the complete diff when its tools cannot read the Git history. Findings must cite `file:line` with a failure scenario; confirm them, stop after two rounds, and hand off unresolved items.
- Source, CI, package contents, installed runtime, release assets, registry, and deployed state are separate evidence layers; one never implies another. Report each layer and name the rest as gaps before considering released, published, installed, or done.
- Never write secrets in code, command arguments, logs, or commits.

## Commit handoff

For commit-worthy uncommitted work, propose the action that matches the real intent of the changes, following the repository's commit convention. Read the unpushed history first (`git log --oneline @{upstream}..`, the whole branch when no upstream exists) and check how the changes relate to it.

- Standalone change, feature, or fix: propose a new commit.
- Continuation of unpushed commits of the same work, such as the rest of a feature, a fix on top of it, or review follow-ups: propose amending or squashing into them, naming each target's short hash and subject.
- Mixed concerns: prefer the fewest commits and propose one even when its scope fits loosely; split only when the repository's history keeps such concerns in separate commits.
- Never rewrite pushed history unless asked; when the matching commit is already pushed, propose a new commit instead.

Render this block with the structure unchanged: fill the change list from the actual diff, one entry per change in the shape shown, and adapt only the proposal part, using Conventional Commits and inferring the appropriate type and optional scope from the changes:

````markdown
### Changes

- [file:line](path/to/file:line) - describes the resulting behavior.

I suggest creating a new commit:

```text
<type>[optional scope]: <description>

[optional body]

[optional footer]
```

Want me to run it?
````

Write the whole message unwrapped; never hard-wrap at a fixed column or trim wording to fit one unless the repository declares a convention or sets commitlint's `body-max-line-length`.

For an amend or squash, keep the change list and adapt only the proposal lines: name the target's short hash and subject, include the resulting message in the fenced block only when it changes, and end with the matching question ("Want me to run the squash?").

For a split, keep one `### Changes` block, divided by a `####` subheader per commit with a short imperative title ("Refactor chat header") and its own change list, and one closing question to end the block ("Want me to run both?"). When the changes span repositories, the subheaders name the repositories instead, and a repository with several commits nests its commit subheaders one level down.

Render the block itself, never a description of it, even when the prompt asks what you would do.
