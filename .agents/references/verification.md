# Verification and delegation

The procedures behind the verification rules in `engineering.md`. Read the section the current task needs.

## Delegation

- Delegate bounded, independent, read-only tasks to the configured explorers and reviewers, never nested, at most 3 concurrent.
- Give each delegate a root, a scope, the evidence to return, and a stop condition.
- The primary owns writes, architecture, synthesis, and verification.
- Parallel writers need explicit permission, isolated worktrees, and disjoint files.
- Workflow and orchestration stages never run Fable-class models, even with approval; a warranted Fable-class review runs afterwards as a standalone subagent.
- Spawning a standalone Fable-class subagent requires asking first; context-inheriting forks cannot change model and are exempt.

## Reviewer protocol

- After multi-file or behavior changes, run a reviewer subagent for correctness, security, spec compliance, and conventions.
- Pass the complete diff when the reviewer's tools cannot read the Git history.
- Every finding cites `file:line` with a failure scenario; confirm each one before acting on it.
- Stop after two review rounds and hand off unresolved items.

## Running services

- Before starting a dev server or service, check for one already running: a listening port, an open terminal, an open tab. Reuse it.
- A port-in-use error means the app is already up. Verify against it; never kill the process or switch to another port.
- Start a new instance only when no running one can serve the change, and ask before restarting one you did not start.

## Evidence layers

- Source, CI, package contents, installed runtime, release assets, registry, and deployed state are separate layers; one never implies another.
- Report each layer checked and name the rest as gaps before calling anything released, published, installed, or done.

## Commit decision

- Read the unpushed history first: `git log --oneline @{upstream}..`, or the whole branch when no upstream exists.
- A standalone change, feature, or fix gets a new commit.
- A continuation of unpushed work (the rest of a feature, a fix on top, review follow-ups) is proposed as an amend or squash.
- Name each amend or squash target by its short hash and subject.
- Mixed concerns get the fewest commits, one even when its scope fits loosely; split only when the repository's history keeps such concerns apart.
- Never rewrite pushed history unless asked; when the matching commit is pushed, propose a new commit.
- When the work addresses a GitHub issue, reference it in the footer (`Closes #12`, `Fixes #12` for bugs, `Refs #12` for partial work) per `github.md`.
