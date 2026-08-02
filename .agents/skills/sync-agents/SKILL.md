---
name: sync-agents
description: >-
  Audit, repair, or scaffold a repository's agentic surface: AGENTS.md, tool
  entrypoints, rules, skills, and hooks. Use for /sync-agents, agent setup, or
  agentic-file reviews; accepts a scope path and --check.
---

# sync-agents

Audit and repair the complete agentic surface of a repository. Optimize four aspects together: instruction quality, discoverability, context efficiency, and maintainability. Never shrink context at the expense of a hard behavior.

Human-facing docs such as README, CONTRIBUTING, CHANGELOG, and `docs/` are out of scope. Read one only to verify whether agent-only material is misplaced, and do not edit it. The `sync-docs` skill owns that surface.

## Arguments

Parse two optional arguments before starting:

- **Scope path or area**: lead in that subtree, then run a light whole-surface pass so global routing and contradictions remain visible. Without a scope, inspect the entire agentic surface.
- **`--check`**: audit and report only. Do not edit, remove, install, update, or regenerate anything.

## Operating contract

- Read and obey the effective instruction chain before acting.
- Resolve symlinks and includes. Edit the canonical source, never a generated entrypoint or alternate route.
- Preserve unrelated user changes and the repository's formatting conventions.
- Never commit or push unless the current prompt explicitly asks.
- Prefer recoverable removals. Delete a tracked duplicate, stale plan, or orphan only when ownership and replacement are clear; ask before ambiguous or untracked removal.
- Treat vendored or manager-owned skills as read-only. Repair them through their declared manager, lockfile, or upstream source instead of local patching.
- Ask only for a decision that materially changes the architecture or cannot be inferred safely. Continue all independent work while it waits.

## Phase 0: resolve the environment

1. Resolve the repository root with Git when possible, otherwise use the current directory.
2. Read root and nearest nested `AGENTS.md` files plus any repository rule that governs agent config, docs, generated files, formatting, or commits.
3. Parse the scope and `--check` arguments.
4. Read these references completely:
   - [references/agentic-architecture.md](references/agentic-architecture.md)
   - [references/context-budgets.md](references/context-budgets.md)
5. If substantive rule edits are possible, also read [references/behavioral-baits.md](references/behavioral-baits.md) and run the applicable baits now to record a baseline.
6. Identify the declared source of truth, managed files, generated files, ignored paths, installed-skill manager, and tool-specific configuration.

Do not infer loader behavior from filenames alone. Inspect the configuration that makes each file discoverable.

## Phase 1: inventory and measure

Use `rg --files`, targeted `find`, `readlink`, and Git status or ignore checks. Inventory at least:

- every root and nested `AGENTS.md`;
- `CLAUDE.md`, `GEMINI.md`, Copilot instructions, Cursor rules, commands, and equivalent tool entrypoints;
- `.agents/`, `.claude/`, `.codex/`, `.copilot/`, `.cursor/`, and `.github/` agentic trees;
- rule files, skills, hooks, output styles, agents, specs, plans, tasks, and artifacts;
- MCP configuration and settings that control instruction or skill discovery;
- symlinks, includes, lockfiles, ignored files, and generated mirrors.

For each item, record its role, owner, loader, scope, physical target, tracked or ignored state, and whether another item duplicates it.

### Build a loader graph

Build a separate effective graph for every configured agent or editor:

1. startup and always-on files;
2. conditionally loaded files and their path or intent trigger;
3. manual routes, imports, includes, and symlink targets;
4. the actual physical files reached;
5. duplicate routes to one target;
6. files no configured route can reach.

Compute the effective startup context from physical files. Keep duplicate routes as findings even if de-duplication makes the token sum look harmless.

### Measure every audit

Run `scripts/count_tokens.py` over all in-scope agentic prose. Always record estimated tokens, even when the repository declares no budget; tokens are the only budget and optimization dimension, and the lines and bytes in the report are informational. Flag hard-wrapped prose in documents: markdown paragraphs and list items are written as single physical lines, and the script reports wrap points as `wrapped-prose`. Scripts are not measured and keep the language's own wrapping conventions. Apply the default profile from `context-budgets.md`; a stricter local limit wins. Measure the total effective always-on stack as well as each file.

For the enabled skill catalog, record:

- total description characters against the discovery budget;
- descriptions over the soft limit;
- exact and semantic duplicates, with one recommended winner;
- enabled, disabled, shadowed, and unreachable entries;
- installed folders that drift from the lockfile or manager state;
- provenance for every third-party entry: source repository, whether the lockfile pins a tag or revision, and the reviewed revision. A source that floats on a default branch is a finding on its own, because the next update pulls whatever that branch holds into files that steer the agent.

Do not load every skill body to evaluate discovery. Start with metadata, then read a body only when its trigger, size, ownership, or overlap is a finding.

## Phase 2: evaluate

Score each aspect from 0 to 10 and support it with concrete evidence:

1. **Instruction quality**: correctness, specificity, priority, completeness, contradictions, and preservation of high-consequence behavior.
2. **Discoverability**: loader coverage, trigger quality, path scopes, entrypoint integrity, and absence of unreachable or shadowed assets.
3. **Context efficiency**: effective startup size, duplication, signal density, catalog cost, progressive disclosure, and task-specific loading.
4. **Maintainability**: one source of truth, ownership, stable structure, automated checks, stale-file control, and low drift risk.

Use the architecture reference to check source-of-truth integrity, nearest-file inheritance, tool fit, scoped loading, stale commands, orphaned assets, generic advice, and content that belongs in executable config instead of prose.

Review specs, plans, and tasks by phase. Keep goals and acceptance criteria in a spec, architecture and verification in a plan, execution state in tasks, and subsystem detail in focused references. A large effort may exceed one file's budget; one phase should not silently become the entire project history.

Classify findings by impact:

- **Hard failure**: contradiction, broken route, unsafe instruction, or a behavioral bait regression.
- **High leverage**: duplicate always-on context, stale source, ambiguous skill trigger, unpinned third-party skill source, or missing source-of-truth guard.
- **Maintenance**: minor metadata, naming, formatting, or organization drift.

## Phase 3: propose and apply

Present the findings, current scores, and recommended changes before mutation when the user asked for approval first. Otherwise apply clear, in-scope fixes in this order:

1. repair broken or duplicate discovery routes;
2. resolve contradictions and preserve hard boundaries;
3. remove recoverable duplicates, stale plans, and proven orphans;
4. compress the always-on stack;
5. move path-specific or procedural detail behind scopes and skills;
6. split large skills, specs, and references by responsibility;
7. tighten descriptions and choose one winner for duplicate skills;
8. add measurement or guards that prevent the same drift.

Treat missing wiring as repairable, not merely reportable. When the repository lacks part or all of the standard project wiring, read [references/project-scaffold.md](references/project-scaffold.md) completely and run its procedure: closed questions in interactive runs, stated defaults otherwise, creating only what is missing and never overwriting.

Under `--check`, replace every mutation with a precise proposed change.

If a documented lockfile manager owns installed skills, use its declared update mechanism and never hand-edit the lockfile. Under `--check`, or when network or external authority is unavailable, report the drift without updating.

Pin third-party skills to a tag or revision where the manager supports it. Where it does not, record the reviewed revision in the audit and read the diff of the installed bodies before accepting the next update. A skill body runs with the user's privileges and rewrites how the agent behaves, so an update is a code change and gets reviewed as one, never waved through as a docs refresh.

Use progressive disclosure, not hidden omission. Entrypoints carry universal high-consequence rules; scoped rules carry path behavior; skills carry procedures; references carry examples, tables, and research one link away.

## Phase 4: verify the candidate

After editing:

1. rerun token, startup-stack, and catalog measurements;
2. validate frontmatter, JSON, TOML, links, symlinks, hook syntax, executable bits, and any repository checks affected by the change;
3. inspect the diff for accidental churn, banned prose, and user changes;
4. rerun the same behavioral baits with fresh subagents using the same model and settings as the baseline;
5. require every hard bait to pass and no aspect to regress;
6. repeat only an ambiguous stochastic failure, otherwise restore or strengthen the rule;
7. rescore all four aspects and explain any remaining score below 8.

Do not claim equal success rate from file size alone. The evidence is a smaller effective context plus unchanged or improved behavior under the same tests.

## Phase 5: recap

Lead with a one-line verdict, then report:

- **Scope**: resolved root, narrowed scope if any, and applied or `--check` mode.
- **Changed** or **Would change**: one line per fix with its reason.
- **Metrics**: before and after startup context, largest files, and catalog size.
- **Scores**: before and after for all four aspects.
- **Decisions pending**: unresolved choices and the recommended option.
- **Follow-ups**: only work that needs the user or an external system.

When the result is commit-worthy, follow the repository's required handoff and offer a Conventional Commit message. Leave the commit to the user.

## Skill authoring standard

When repairing a skill, keep it portable within its claimed domain, driven by repository evidence rather than machine assumptions, and functional when an optional dependency is absent. Its description states what it does and when it should trigger; workflow detail belongs in the body or a one-level reference. Every created or modified skill receives the four aspect scores, its applicable context-budget checks, and representative behavior and trigger evals. Use `skill-creator` for the eval loop; `sync-agents` owns architecture and context criteria even when another skill initiated the work.

## Bundled resources

- [references/agentic-architecture.md](references/agentic-architecture.md): file taxonomy, default project wiring, and architecture rubric.
- [references/project-scaffold.md](references/project-scaffold.md): the interactive bootstrap procedure for a repository without agentic docs.
- [references/context-budgets.md](references/context-budgets.md): default token, startup, catalog, skill, spec, and reference envelopes plus the unwrapped-prose rule.
- [references/behavioral-baits.md](references/behavioral-baits.md): baseline and candidate regression scenarios.
- `scripts/count_tokens.py`: per-file, total-stack, profile, and catalog metrics.
