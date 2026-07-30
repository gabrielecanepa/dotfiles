# AGENTS.md

Machine-wide guidance for Claude Code, Codex, and Copilot. More specific project instructions override it; explicit user requests override both.

## Hard boundaries

- **Version control:** Never run `git commit`, `git push`, or another history-writing command unless the current prompt explicitly asks. Full boundary and handoff format: `engineering.instructions.md`.
- **Committed writing:** Never use an em dash or en dash in a committed file; live chat is the only exception. Full prose rules: `writing.instructions.md`.
- **Portable paths:** Never write a machine-specific absolute path or identifier (`/Users/<name>`, hostname, serial, personal email) into a file; use `$HOME`, `~`, `$HOMEBREW_PREFIX`, `$XDG_*`, or a repo-relative path. Hardcoding one requires an explicit ask or user approval.
- **Scope:** Preserve unrelated changes. Do not broaden scope for adjacent work.

## Rule routing

Claude Code and Copilot load the shared rules automatically. Codex must read `behavior.instructions.md` and `engineering.instructions.md` before any task, then read every rule relevant to the work:

- UI work: `design.instructions.md` carries the design discipline and the aesthetic flavors inline.
- React or Next.js: `react.instructions.md`, `vercel-react-best-practices`, and `vercel-composition-patterns` for non-trivial component design.
- TypeScript: `typescript.instructions.md`.
- Animation or motion work: `motion.instructions.md` for easing, duration, and spring values, routes the animation review skills, and pins the Motion docs sources.
- Server-side Node.js: `node.instructions.md`.
- Shell scripts: `shell.instructions.md`.
- Human-facing prose longer than a few sentences: `writing.instructions.md` and `humanizer`.
- Agentic documentation or skills: `sync-agents`; add `skill-creator` when creating or modifying a skill.
- Library, framework, or API questions: `context7-mcp`.
- Browser driving or real UI verification: `browser.instructions.md` and `agent-browser`.
- This machine's dotfiles: `dotfiles.instructions.md`.

The canonical files live under `~/.agents/`. `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, and Copilot entrypoints link there. Edit the source, not a symlinked route, and do not copy the same instructions into multiple files.

## Environment and tools

- macOS on Apple Silicon; Homebrew prefix `/opt/homebrew`; VS Code and Ghostty.
- Project code lives under `~/Developer`; `$HOME` is the dotfiles git repository.
- Personal, work, and per-client contexts are strictly separated: each has its own email account, macOS desktop, and Chrome window, and client projects live under `~/Developer/@<client>`. Target browser, email, and calendar automation at the active context's account and Chrome window only. Git identity and per-client overrides live in the untracked `~/.gitconfig`; never hardcode an email into tracked config.
- Obsidian vaults live only under `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/`. Never substitute `~/Documents` or another guessed path.
- zsh uses custom functions under `~/.zsh`. Check the matching plugin before treating commands such as `profile`, `plugin`, `brew`, `mas`, `lts`, `deps`, or `dotfiles` as binaries.
- Node uses `nodenv`; Python uses `pyenv`; Ruby uses `rbenv`. Do not introduce mise, asdf, nvm, or Volta unless asked.
- Default Node package manager: pnpm through Corepack. Respect a project's lockfile when it selects npm or bun. Use the version-manager shims, not system runtimes.

## Git

- Commits are signed through the 1Password SSH agent. Never disable signing or add `--no-gpg-sign`.
- Follow the target repository's commit convention. Do not add AI attribution or `Co-authored-by` trailers.
- The `$HOME` repository has its own allowed types and scopes in `dotfiles.instructions.md`.

## Generated files

- Put one-shot scripts, logs, and scratch data in the session scratchpad or system temp directory, never in a repository.
- Put reusable agent artifacts under an existing agentic folder's `artifacts/` directory. Prefer the agent's non-symlinked folder, else `.agents/`. If no such folder exists, follow the repository or user-specified destination instead of creating one.

## Formatting

Repository configuration owns formatting. Use `oxfmt` for JS, TS, CSS, and JSON; RuboCop for Ruby; `shfmt` plus `shellcheck` for shell; and `.editorconfig` for general files. Run the configured tool and avoid unrelated reformatting.
