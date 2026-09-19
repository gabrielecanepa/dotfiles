---
description: 'Use for agent configuration in the $HOME dotfiles: shared instructions, native Claude, Codex, Copilot, and OpenCode assets, skills, hooks, statuslines, loader routes, and private config.'
applyTo: '.agents/**,.claude/**,.codex/**,.config/opencode/**,.copilot/**,.vscode/settings.json,Library/Application Support/Code/User/settings.json,.gitignore,.install.sh,.oxfmtrc.json'
paths:
  - '.agents/**'
  - '.claude/**'
  - '.codex/**'
  - '.config/opencode/**'
  - '.copilot/**'
  - '.vscode/settings.json'
  - 'Library/Application Support/Code/User/settings.json'
  - '.gitignore'
  - '.install.sh'
  - '.oxfmtrc.json'
---

# Agent configuration

These rules apply only when `$HOME` is the active repository. Loader, hook, and statusline internals: `~/.agents/references/dotfiles-loaders.md`.

## Sources and loader routes

- Edit the tool-neutral sources under `.agents/{AGENTS.md,hooks,references,rules,skills}`; the provider entrypoints are tracked relative links.
- Never edit through a link or copy shared instructions into a provider tree.
- Claude loads `.claude/CLAUDE.md`, rules through `.claude/rules`, and skills through `.claude/skills`; a rule without `paths` is always on.
- A scoped rule carries matching `paths` and `applyTo` metadata.
- Codex loads `.codex/AGENTS.md` and `.codex/skills` and has no scoped rule loader, so `AGENTS.md` routes rules by intent.
- OpenCode loads `.config/opencode/AGENTS.md` plus every `AGENTS.md` toward the workspace; V2 ignores `instructions[]` and `CLAUDE.md`.
- Copilot loads `.copilot/copilot-instructions.md` and `.copilot/instructions`, a real directory of `<rule>.instructions.md` links to `.agents/rules/<rule>.md`.
- When adding a rule, add its link in `.copilot/instructions`; `~/.copilot/instructions` stays the only enabled instructions root in `.vscode/settings.json`.
- OpenCode discovers skills from `.claude/skills` and `.agents/skills` with no extra wiring; never copy a skill into `.config/opencode/skills`.
- Keep tool-native assets in place: `.claude/{agents,commands,output-styles}`, `.codex/agents`, `.codex/hooks.json`, `.copilot/*.json`, `.config/opencode/{agents,commands}`, and `opencode.jsonc`.

## Provider configuration

- Track portable Copilot defaults and inline hooks in `.copilot/settings.json` and language servers in `.copilot/lsp-config.json`.
- Keep the user's Copilot model, effort, and interface choices; check every key against `copilot help config`.
- Keep MCP servers, credentials, permissions, plugins, and session state ignored and CLI-managed; never duplicate skills into `.copilot/skills`.
- Track portable Codex defaults in `.codex/settings.toml`; keep the ignored `.codex/config.toml` a regular file with mode `600` for private state and secrets.
- Track portable OpenCode defaults in `.config/opencode/opencode.jsonc`; keep secrets in `{env:NAME}` references, never plaintext.
- Ongoing shell startup may repair user-owned state but never invokes `sudo`.

## Hooks, memory, and statuslines

- `.agents/hooks` holds shared agent hooks, not Git hooks: keep behavior in each script header and register each script by its `$HOME/.agents/hooks` path.
- Register shared hooks in `.claude/settings.json`, `.codex/hooks.json`, and `.copilot/settings.json`; a hook reads both Claude and Copilot field spellings.
- Treat the write guards as best effort; a `Bash` redirect reaches disk unchecked, so reread committed prose before pushing.
- Claude auto memory writes machine-local notes under `~/.claude/projects/<project>/memory/`; keep the directory untracked.
- During agent-surface reviews, run `/compact-memory`: fold durable learnings into tracked rules and prune the rest.
- The statuslines are `.claude/statusline.sh` and `.claude/subagent-statusline.sh`; update a script header and `.claude/statusline.schema.json` together.
- Keep statusline scripts Bash 3.2 compatible, expand possibly-empty arrays as `${arr[@]+"${arr[@]}"}`, and fail open per `shell.md`.

## Instruction style and budgets

- Follow the instruction style in `.agents/skills/sync-agents/references/agentic-architecture.md`: one directive per line, trigger first.
- Write to the targets in `.agents/skills/sync-agents/references/context-budgets.md`; the cap is the failure line.
- `guard-context-budgets.sh` measures every agentic write; fix a reported breach before continuing.

## Skills and subagents

- Install manager-owned skills from `~` with `npx skills add <owner/repo> --skill <name> --global --yes`; update with `npx skills update --global --yes`.
- The manager owns its skill folders and `.agents/.skill-lock.json`; never hand-edit either, and never let a project-level `~/skills-lock.json` exist.
- Locally authored skills are allowlisted and tracked directly, outside the manager lock.
- Treat `.agents/skills/.system` as tool-owned: disable unwanted bundled skills through provider configuration and never move, track, or delete them.
- Keep Codex skill-path overrides in the single private `.codex/config.toml`, never split across public and private layers.
- Before installing a skill, check the catalog for a same-name skill and keep its description within the discovery budget.
- Keep native subagents narrow and read-only by default: Claude in `.claude/agents/*.md`, Codex in `.codex/agents/*.toml`, OpenCode in `.config/opencode/agents/*.md`, roles aligned.
