# AGENTS.md

Machine-wide guidance for coding agents. More specific project instructions override it; explicit user requests override both.

## Hard boundaries

- **Version control:** Never run `git add`, `git commit`, `git push`, or another history-writing command unless the current prompt explicitly asks. Handoff format: `engineering.instructions.md`.
- **Committed writing:** Never use an em dash or en dash in a committed file; live chat is the only exception. Full prose rules: `writing.instructions.md`.
- **Portable paths:** Never write a machine-specific absolute path or identifier (`/Users/<name>`, hostname, serial, personal email) into a file; use `$HOME`, `~`, `$HOMEBREW_PREFIX`, `$XDG_*`, or a repo-relative path. Hardcoding one requires an explicit ask or user approval.
- **Scope:** Preserve unrelated changes. Do not broaden scope for adjacent work.

## Rule routing

Claude Code and Copilot load matching rules automatically. Other agents read `behavior.instructions.md` and `engineering.instructions.md` before every task, then the applicable rules:

- Shell scripts: `shell.instructions.md`.
- TypeScript: `typescript.instructions.md`
- Node.js: `node.instructions.md`.
- React or Next.js: `react.instructions.md`.
- UI: `design.instructions.md` and `motion.instructions.md` for animation or motion.
- Browser work or real UI verification: `browser.instructions.md`.
- Human prose beyond a few sentences: `writing.instructions.md`.
- `$HOME` dotfiles: `dotfiles.instructions.md`.
- Skills: `find-root-cause` (bugs, regressions, failing tests), `context7-mcp` (library, framework, or API questions), `sync-agents` and `skill-creator` (agentic docs and skills).

Shared sources are in `~/.agents/`; provider entrypoints are links, never edit targets. Do not duplicate these instructions.

## Environment

- macOS on Apple Silicon; Homebrew at `/opt/homebrew`; VS Code and Ghostty.
- Project code is under `~/Developer`; `$HOME` is the dotfiles git repository.
- Keep personal, work, and client contexts separate: browser, email, and calendar work targets only the active context's accounts. Client projects live under `~/Developer/@<client>`; identity overrides are in the untracked `~/.gitconfig`.
- The only Obsidian vault is `~/.vault`; reference it only through that path, never the iCloud folder it resolves to.
- Zsh uses custom plugins and themes under `~/.zsh`; check the matching plugin before treating commands like `profile`, `plugin`, `brew`, `mas`, `lts`, `deps`, or `dotfiles` as binaries.
- Runtimes: `nodenv` (Node), `pyenv` (Python), `rbenv` (Ruby); introduce no other runtime or version manager unless asked. Use the shims, not system runtimes.
- The default Node package manager is pnpm through Corepack; the project's lockfile always wins.
- Repository config owns formatting: oxfmt for JS, TS, CSS, JSON; shfmt and shellcheck for shell; `.editorconfig` otherwise. Always run the configured formatter.
- Scratch scripts, logs, and data go in the session scratchpad or system temp directory, never a repository.

## Git

- Commits are signed with the local SSH key through git's default `ssh-keygen` signer. Never disable signing or use `--no-gpg-sign`.
- Follow the target repository's commit conventions. Never use AI attribution or `Co-authored-by` trailers.
- `$HOME` types and scopes: `dotfiles.instructions.md`.
