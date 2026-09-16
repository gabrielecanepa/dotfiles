---
name: sync-agents
description: >-
  Audits, repairs, or scaffolds a repository's agentic surface: AGENTS.md,
  entrypoints, rules, skills, hooks. Use for /sync-agents, agent setup, or
  agentic-file reviews; takes a scope path and --check.
---

# sync-agents

Audit and repair a repository's agentic surface for instruction quality, discoverability, context efficiency, and maintainability.

Never shrink context at the expense of a hard behavior.

Human-facing docs (README, CONTRIBUTING, CHANGELOG, `docs/`) belong to `sync-docs`: read one only to spot misplaced agent rules, never edit it.

## Arguments

- With a scope path or area, lead there, then run a light whole-surface pass so global routing and contradictions stay visible.
- Without a scope, inspect the entire agentic surface.
- With `--check`, audit and report only: never edit, remove, install, update, or regenerate.

## Operating contract

- Read and obey the effective instruction chain before acting.
- Resolve symlinks and includes; edit the canonical source, never a generated entrypoint or alternate route.
- Preserve unrelated user changes and the repository's formatting; never commit or push unless the prompt asks.
- Prefer recoverable removals: delete a tracked duplicate, stale plan, or orphan only with clear ownership and replacement, else ask.
- Treat a vendored or manager-owned skill as read-only; repair it through its manager, lockfile, or upstream, not a local patch.
- Never write this skill's bundled files or any path under `~` into a repository; record budgets as numbers.
- Name `/sync-agents --check` to measure them, or commit a check script inside the repository.
- Ask only for a decision that changes the architecture or cannot be inferred safely; continue independent work while it waits.

## Phase 0: resolve the environment

1. Resolve the repository root with Git, else the current directory.
2. Read the root and nearest nested `AGENTS.md`, plus rules on agent config, docs, generated files, formatting, or commits.
3. Parse the scope and `--check` arguments.
4. Read [agentic-architecture.md](references/agentic-architecture.md) and [context-budgets.md](references/context-budgets.md) completely.
5. Before substantive rule edits, run the applicable [behavioral-baits.md](references/behavioral-baits.md) scenarios for a baseline.
6. Identify the declared source of truth, managed and generated files, ignored paths, the skill manager, and tool configuration.

Never infer loader behavior from filenames; inspect the configuration that makes a file discoverable.

## Phase 1: inventory and measure

Use `rg --files`, `find`, `readlink`, and Git status or ignore checks. Inventory at least:

- entrypoints: every root and nested `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, Copilot instructions, Cursor rules, and commands;
- trees: `.agents/`, `.claude/`, `.codex/`, `.copilot/`, `.cursor/`, and `.github/`;
- assets: rules, skills, hooks, output styles, agents, specs, plans, tasks, and artifacts;
- MCP configuration and settings that control instruction or skill discovery;
- symlinks, includes, lockfiles, ignored files, and generated mirrors;
- tool-written memory loaded at startup, such as Claude auto memory (`~/.claude/projects/<project>/memory/MEMORY.md`);
- for memory, the loaded index, stale entries, and learnings worth promoting into the tracked stack.

Record for each item its role, owner, loader, scope, physical target, tracked or ignored state, and any duplicate.

### Build a loader graph

Per configured agent or editor, map:

1. startup and always-on files;
2. conditionally loaded files and their path or intent trigger;
3. manual routes, imports, includes, and symlink targets;
4. the physical files actually reached;
5. duplicate routes to one target, and files no configured route can reach.

Compute the effective startup context from physical files; keep a duplicate route as a finding even when de-duplication hides it.

### Measure every audit

- Run `scripts/count_tokens.py` over all in-scope agentic prose, recording tokens even where no budget is declared.
- Tokens are the only budget dimension; reported lines and bytes are informational.
- Flag hard-wrapped prose, reported as `wrapped-prose`; scripts are not measured and keep the language's own wrapping.
- Apply the default profile from [context-budgets.md](references/context-budgets.md); a stricter local limit wins.
- Measure the total effective always-on stack as well as each file.
- Measure the enabled catalog: description characters, over-limit descriptions, duplicates with one winner, and disabled or unreachable entries.
- Flag folders that drift from the lockfile, and record each third-party source repository, its pin, and the reviewed revision.
- Start with metadata; read a skill body only when its trigger, size, ownership, or overlap is a finding.

## Phase 2: evaluate

Score each aspect from 0 to 10 with concrete evidence:

1. Instruction quality: correctness, specificity, priority, completeness, contradictions, hard behaviors.
2. Discoverability: loader coverage, triggers, path scopes, entrypoint integrity, no shadowed or unreachable assets.
3. Context efficiency: startup size, duplication, signal density, catalog cost, disclosure, scoped loading.
4. Maintainability: one source of truth, ownership, structure, automated checks, stale files, drift risk.

Apply the architecture and signal-density checks in [agentic-architecture.md](references/agentic-architecture.md) to in-scope files.

Review specs, plans, and tasks by phase:

- Keep goals and criteria in a spec, architecture and verification in a plan, state in tasks, detail in references.
- A large effort may exceed one file's budget, but one phase must not become the whole project history.

### Findings

- Hard failure: contradiction, broken route, unsafe instruction, or a bait regression.
- High leverage: duplicate always-on context, stale source, ambiguous trigger, unpinned third-party source, or missing source-of-truth guard.
- Maintenance: minor metadata, naming, formatting, or organization drift.

## Phase 3: propose and apply

- When the user asked for approval first, present findings, scores, and recommended changes before any mutation.
- Otherwise apply clear, in-scope fixes in the order below.
- Under `--check`, replace every mutation with a precise proposed change.
- Treat missing wiring as repairable, not merely reportable.
- When standard wiring is missing in part or whole, read [project-scaffold.md](references/project-scaffold.md) fully and run its procedure.
- Scaffold with closed questions interactively, stated defaults otherwise, creating only what is missing and never overwriting.
- Use progressive disclosure, not omission: entrypoints carry high-consequence rules, scoped rules path behavior, skills procedures, references detail.

### Fix order

1. repair broken or duplicate discovery routes;
2. resolve contradictions and preserve hard boundaries;
3. remove recoverable duplicates, stale plans, and proven orphans;
4. compress the always-on stack;
5. move path-specific or procedural detail behind scopes and skills;
6. split large skills, specs, and references by responsibility;
7. tighten descriptions and pick one winner for duplicate skills;
8. add measurement or guards that prevent the same drift.

### Third-party skills

- When a lockfile manager owns installed skills, use its declared update mechanism and never hand-edit the lockfile.
- Under `--check`, or without network or external authority, report drift without updating.
- Pin, record, and diff-review each third-party skill per "Skill provenance" in [agentic-architecture.md](references/agentic-architecture.md).

## Phase 4: verify the candidate

After editing:

1. rerun token, startup-stack, and catalog measurements;
2. validate frontmatter, JSON, TOML, links, symlinks, hook syntax, executable bits, and affected repository checks;
3. inspect the diff for churn, banned prose, user changes, and any path outside the repository (`~`, `$HOME`, `/Users`, this skill's files);
4. rerun the same baits with fresh subagents on the baseline model and settings;
5. require every hard bait to pass and no aspect to regress;
6. repeat only an ambiguous stochastic failure, otherwise restore or strengthen the rule;
7. rescore all four aspects and explain any remaining score below 8.

Never claim equal success from file size: the evidence is a smaller context with behavior unchanged under the same tests.

## Phase 5: recap

Lead with a one-line verdict, then report:

- Scope: resolved root, narrowed scope if any, and applied or `--check` mode.
- Changed, or Would change under `--check`: one line per fix with its reason.
- Metrics: before and after startup context, largest files, and catalog size.
- Scores: before and after for all four aspects.
- Decisions pending: unresolved choices and the recommended option.
- Follow-ups: only work that needs the user or an external system.

When the result is commit-worthy, follow the repository's handoff and offer a Conventional Commit message. Leave the commit to the user.

## Skill authoring standard

- Keep a repaired skill portable in its domain, driven by repository evidence, and working when an optional dependency is absent.
- Its description states what it does and when it triggers; workflow detail belongs in the body or one reference.
- Give every created or modified skill the four scores, its budget checks, and behavior and trigger evals.
- Use `skill-creator` for the eval loop; `sync-agents` owns architecture and context criteria even when another skill started it.

## Bundled resources

- [agentic-architecture.md](references/agentic-architecture.md): rubric.
- [project-scaffold.md](references/project-scaffold.md): bootstrap.
- [context-budgets.md](references/context-budgets.md): envelopes.
- [behavioral-baits.md](references/behavioral-baits.md): regressions.
- `scripts/count_tokens.py`: metrics.
