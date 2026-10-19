---
description: "Use for agent configuration in the $HOME dotfiles: shared instructions, tool settings, skills, hooks, and loader routes."
applyTo: ".agents/**,.claude/**,.codex/**,.config/opencode/**,.copilot/**,.pi/**,.vscode/user/**,.vscode/settings.json,.gitignore,.oxfmtrc.json"
paths:
  - ".agents/**"
  - ".claude/**"
  - ".codex/**"
  - ".config/opencode/**"
  - ".copilot/**"
  - ".pi/**"
  - ".vscode/user/**"
  - ".vscode/settings.json"
  - ".gitignore"
  - ".oxfmtrc.json"
---

# Agent configuration

Applies only in the `$HOME` repository. Loader detail: `~/.agents/references/dotfiles-loaders.md`.

## Sources

- Edit shared `.agents` sources; provider entrypoints are relative links.
- Never edit through a link or copy shared instructions into a provider tree.

## Loader routes

- Claude loads `.claude/CLAUDE.md`, `.claude/rules`, and `.claude/skills`; rules without `paths` are always on.
- A scoped rule carries matching `paths` and `applyTo` metadata.
- Codex loads `.agents/skills` and `.codex/AGENTS.md` routes scoped rules.
- OpenCode loads `.config/opencode/AGENTS.md` and workspace `AGENTS.md`; V2 ignores `instructions[]` and `CLAUDE.md`.
- Copilot loads `.copilot/copilot-instructions.md` and `.copilot/instructions`, whose `<rule>.instructions.md` links target `.agents/rules/<rule>.md`.

## Tool assets

- When adding a rule, add its `.copilot/instructions` link and verify that the installed client loads it.
- OpenCode discovers `.claude/skills` and `.agents/skills`; never copy a skill into `.config/opencode/skills`.
- Pi loads `.pi/agent`; its global skill catalog includes `.agents/skills`.
- Keep native assets in `.claude/{agents,commands,output-styles}`, `.codex/{agents,skills,hooks.json}`, `.copilot/*.json`, `.config/opencode`, and `.pi/agent`.

## Provider configuration

- Track Copilot defaults and hooks in `.copilot/settings.json`, and language servers in `.copilot/lsp-config.json`.
- Keep the user's Copilot model, effort, and interface choices; check every key against `copilot help config`.
- Keep Copilot private state CLI-managed; never duplicate skills into `.copilot/skills`.
- Track Codex defaults in `.codex/settings.toml`; keep `.codex/config.toml` private and mode `600`.
- Track portable OpenCode defaults in `.config/opencode/opencode.json`; use `{env:NAME}` for secrets, never plaintext.
- Track Pi defaults in `.pi/agent/settings.json` and extensions in `.pi/agent/extensions`; ignore state.
- Ongoing shell startup may repair user-owned state but never invokes `sudo`.

## Hooks, memory, and statuslines

- `.agents/hooks` holds agent, not Git, hooks; register each script by its `$HOME/.agents/hooks` path.
- Register shared hooks in `.claude/settings.json`, `.codex/hooks.json`, and `.copilot/settings.json`; a hook reads both Claude and Copilot field spellings.
- Treat write guards as best effort; a `Bash` redirect reaches disk unchecked.
- Claude auto memory writes machine-local notes under `~/.claude/projects/<project>/memory/`. Keep the directory untracked and run `/compact-memory` for auto-memory reviews.
- Update `.claude/{statusline.sh,subagent-statusline.sh}` and `statusline.schema.json` together.
- Keep statusline scripts Bash 3.2 compatible, expand possibly-empty arrays as `${arr[@]+"${arr[@]}"}`, and fail open per `shell.md`.

## Instruction style and budgets

- Follow `.agents/skills/sync-agents/references/agentic-architecture.md`: one directive per line, trigger first.
- Write to the targets in `.agents/skills/sync-agents/references/context-budgets.md`; the cap is the failure line.
- `guard-context-budgets.sh` measures every agentic write; fix a reported breach before continuing.

## External skills

- External skills are untracked and listed in `.agents/.skill-lock.json`; untracked alone does not establish ownership.
- Never hand-edit external skill files or lock entries, including descriptions, scripts, and metadata.
- Install with `npx skills add <owner/repo> --skill <name> --global --yes`; update with `npx skills update -g <names...> --yes`.
- Never create a project-level `~/skills-lock.json`.

## Local skills and subagents

- Locally authored skills are allowlisted and tracked directly, outside the manager lock.
- Treat `.codex/skills/.system` as tool-owned and never move, track, or delete them.
- Keep Codex skill-path overrides in the single private `.codex/config.toml`, never split across public and private layers.
- Before installing a skill, check for duplicate names; enforce description budgets only on locally authored skills.
- Keep native subagents narrow, read-only by default, and aligned across provider `agents/` directories.
