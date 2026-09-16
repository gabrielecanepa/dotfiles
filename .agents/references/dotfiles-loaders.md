# Dotfiles loaders and hooks

Detail behind `agent-config.md`: how each tool discovers the shared sources, how hooks are registered per tool, and the memory and statusline internals.

## VS Code and Copilot loading

- VS Code bundles the same `@github/copilot` engine as the CLI, reads `.copilot`, and treats `.copilot/instructions` as a built-in root.
- In `chat.instructionsFilesLocations`, only `false` entries carry weight; built-in roots are on by default, so a `true` entry only documents intent.
- VS Code dedupes symlinked `AGENTS.md`, `CLAUDE.md`, and `copilot-instructions.md` by real path but never `*.instructions.md`.
- VS Code loads file-scoped instructions only from `*.instructions.md` names, so `.copilot/instructions` holds suffixed links to `.agents/rules/<rule>.md`.
- `.vscode/settings.json` keeps `~/.copilot/instructions` on and disables `.agents/rules`, `.claude/rules`, and `.github/instructions`.
- The same file disables `chat.useAgentsMdFile` and `chat.useClaudeMdFile`.
- The tracked user `settings.json` under `Library/Application Support/Code/User` keeps only the two Claude-root disables.

## Copilot hooks

- Register hooks inline in `.copilot/settings.json` with PascalCase event names.
- Use `tool_name` values `Write`, `Edit`, or `Bash`, never the native `create` or `str_replace`.
- Copilot sends `path`, `file_text`, `old_str`, and `new_str`; Claude sends `file_path`, `content`, `old_string`, and `new_string`, so a shared hook reads both.
- A pre-tool error blocks the write; a timeout falls through to normal permissions.
- Write matchers cover `Edit` and `Write` only, so a `Bash` redirect reaches disk unchecked; `pre-push` re-checks portability but never dashes.
- Copilot bills every subagent, so `subagents.maxConcurrency` 3 and `subagents.maxDepth` 1 match the shared limits.

## Codex configuration

- `.codex/settings.toml` is the tracked public layer, exposed as `/etc/codex/config.toml` through a system link created by `.install.sh`.
- `.codex/config.toml` is ignored, mode `600`, and holds private state, secrets, and complete private MCP definitions.
- Keep each MCP transport and its secret headers in one effective layer; a split definition loses the headers.
- A higher-layer `skills.config` array replaces the lower one, so every skill-path override lives in the private file.

## Claude memory and statuslines

- Auto memory is `autoMemoryEnabled` in `.claude/settings.json`; the first 200 lines or 25KB of each `MEMORY.md` load every session outside the tracked stack.
- `.claude/statusline.sh` and `.claude/subagent-statusline.sh` are the two allowlisted executable entrypoints wired in `.claude/settings.json`.
- Both read `.claude/statusline.json`; `subagent-statusline.sh` reads only its `subagent` key.
- `$CLAUDE_STATUSLINE_CONFIG` is the only environment variable that points at an alternate config file.
- `/statusline-config` consumes `.claude/statusline.schema.json` instead of duplicating valid values, so the schema and each script header change together.
