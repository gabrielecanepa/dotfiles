# Dotfiles loaders and hooks

Detail behind `../rules/agent-config.md`: instruction discovery, per-tool hooks, memory, and statuslines.

## VS Code and Copilot loading

- Verify instruction discovery in the installed VS Code and Copilot versions; do not infer editor behavior from the CLI.
- Check effective `chat.instructionsFilesLocations` settings before adding a route.
- Resolve symlink targets when checking duplicate routes; verify whether the installed client deduplicates them.
- VS Code loads file-scoped instructions only from `*.instructions.md` names, so `.copilot/instructions` holds suffixed links to `.agents/rules/<rule>.md`.
- `.vscode/settings.json` disables `chat.useAgentsMdFile` and `chat.useClaudeMdFile`; it sets no instruction-file locations.
- `.vscode/user/settings.json` disables `.claude/rules` and `~/.claude/rules` in `chat.instructionsFilesLocations`.

## Copilot hooks

- Register hooks inline in `.copilot/settings.json` with PascalCase event names.
- Use `tool_name` values `Write`, `Edit`, or `Bash`, never the native `create` or `str_replace`.
- Copilot sends `path`, `file_text`, `old_str`, and `new_str`; Claude sends `file_path`, `content`, `old_string`, and `new_string`, so a shared hook reads both.
- A pre-tool error blocks the write; a timeout falls through to normal permissions.
- Write matchers cover `Edit` and `Write` only, so a `Bash` redirect reaches disk unchecked; `pre-push` re-checks portability but never dashes.
- Copilot bills every subagent, so `subagents.maxConcurrency` 3 and `subagents.maxDepth` 1 match the shared limits.

## Codex configuration

- `.codex/settings.toml` is the tracked public layer, exposed as `/etc/codex/config.toml` through a system link.
- `.codex/config.toml` is ignored, mode `600`, and holds private state, secrets, and complete private MCP definitions.
- Keep each MCP transport and its secret headers in one effective layer; a split definition loses the headers.
- A higher-layer `skills.config` array replaces the lower one, so every skill-path override lives in the private file.

## Claude memory and statuslines

- Auto memory is `autoMemoryEnabled` in `.claude/settings.json`; the first 200 lines or 25KB of each `MEMORY.md` load every session outside the tracked stack.
- `.claude/statusline.sh` and `.claude/subagent-statusline.sh` are the two allowlisted executable entrypoints wired in `.claude/settings.json`.
- Both read `.claude/statusline.json`; `subagent-statusline.sh` reads only its `subagent` key.
- `$CLAUDE_STATUSLINE_CONFIG` is the only environment variable that points at an alternate config file.
- `/statusline-config` consumes `.claude/statusline.schema.json` instead of duplicating valid values, so the schema and each script header change together.
