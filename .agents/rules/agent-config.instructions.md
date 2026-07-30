---
description: 'Use for agent configuration in the $HOME dotfiles repository: shared instructions, native Claude and Codex agents, skills, hooks, statuslines, loader routes, and public/private Codex configuration.'
applyTo: '.agents/**,.claude/**,.codex/**,.copilot/**,.vscode/settings.json,.vscode/user/settings.json,.gitignore,.install.sh,.oxfmtrc.json'
paths:
  - '.agents/**'
  - '.claude/**'
  - '.codex/**'
  - '.copilot/**'
  - '.vscode/settings.json'
  - '.vscode/user/settings.json'
  - '.gitignore'
  - '.install.sh'
  - '.oxfmtrc.json'
---

# Agent configuration

These rules apply only when `$HOME` is the active repository.

## Sources and loader routes

- Edit tool-neutral shared sources under `.agents/{AGENTS.md,hooks,references,rules,skills}`. The `.claude`, `.codex`, and `.copilot` entrypoints are tracked relative links; never edit through a link or copy shared instructions.
- Claude loads `.claude/CLAUDE.md`, user rules through `.claude/rules`, and skills through `.claude/skills`. Rules without `paths` are always on; scoped rules carry matching `paths` and `applyTo` metadata.
- Codex loads `.codex/AGENTS.md` and discovers `.codex/skills`; it has no scoped rule loader, so `AGENTS.md` routes rules by intent. Shared hooks are registered in `.codex/hooks.json`.
- Copilot loads `.copilot/copilot-instructions.md` and `.copilot/instructions`. Do not restore duplicate `.github` home routes.
- In VS Code's `chat.instructionsFilesLocations`, only `false` entries carry weight; built-in roots are on by default, so a `true` entry is a no-op. VS Code dedupes symlinked `AGENTS.md`, `CLAUDE.md`, and `copilot-instructions.md` by real path but never `*.instructions.md`, so `.vscode/settings.json` names `.agents/rules` and disables every colliding root plus `chat.useAgentsMdFile` and `chat.useClaudeMdFile`, while `.vscode/user/settings.json` keeps only the two Claude-root disables.
- Additional agents should use native `~/.agents/AGENTS.md` and `~/.agents/skills` discovery when available. Add a thin provider adapter only for unsupported surfaces, and keep provider schemas out of shared prose.
- Tool-native assets remain in place because their formats differ: `.claude/{agents,commands,output-styles}`, `.codex/agents`, `.codex/hooks.json`, and `.copilot/settings.json`.

## Configuration and hooks

- Track portable Codex defaults in `.codex/settings.toml`, exposed as `/etc/codex/config.toml`. Keep ignored `.codex/config.toml` as a regular file with mode `600` for writable private state, secrets, and complete private MCP definitions. Keep each MCP transport and its secret headers in one effective layer.
- `.install.sh` creates the private Codex file and the system link independently. Ongoing shell startup may repair user-owned state but must not invoke `sudo`.
- `.agents/hooks` contains shared agent hooks, not Git hooks. Keep behavior in each script's header, keep scripts executable, and register each script in the tool-specific configuration by its `$HOME/.agents/hooks` path.
- Claude statuslines are two allowlisted executable entrypoints wired in `.claude/settings.json`: `.claude/statusline.sh` and `.claude/subagent-statusline.sh`. `statusline.sh` reads its settings from `.claude/statusline.json`, and `$CLAUDE_STATUSLINE_CONFIG` is the only environment variable it reads, pointing at an alternate config file. Update the script header and `.claude/statusline.schema.json` together; `/statusline-config` consumes the schema rather than duplicating valid values. Keep statusline scripts compatible with Bash 3.2, expanding possibly-empty arrays as `${arr[@]+"${arr[@]}"}`, and fail open as required by `shell.instructions.md`.

## Skills and subagents

- Install manager-owned skills from `~` with `npx skills add <owner/repo> --skill <name> --global --yes`; update them with `npx skills update --global --yes`. The manager owns their folders and `.agents/.skill-lock.json`; never hand-edit either. `--global` is required: without it the CLI writes a project-level `~/skills-lock.json`, which must never exist.
- Locally authored skills are allowlisted and tracked directly, so the manager lock is not their source of truth. Treat `.agents/skills/.system` as tool-owned: disable unwanted bundled skills through supported provider configuration, and never move, track, or delete generated folders.
- User-specific Codex skill-path overrides are in the private `.codex/config.toml`. A higher-layer `skills.config` array replaces the lower one, so keep every entry in the single private layer and never split them across public and private configuration.
- Before installing a skill, inspect the catalog and avoid a second discoverable skill with the same name. Keep discovery descriptions specific and concise so the complete catalog remains under the loader's description budget.
- Keep native subagents narrow and read-only by default. Claude definitions are in `.claude/agents/*.md`; Codex definitions in `.codex/agents/*.toml`. Align role behavior across tools, while model, effort, permissions, and sandbox remain native settings.
