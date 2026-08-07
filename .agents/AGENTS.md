# AGENTS.md

Machine-wide guidance for coding agents. More specific project instructions override it; explicit user requests override both.

## Hard boundaries

- **Version control:** Never run `git commit`, `git push`, or another history-writing command unless the current prompt explicitly asks. Full boundary and handoff format: `engineering.instructions.md`.
- **Committed writing:** Never use an em dash or en dash in a committed file; live chat is the only exception. Full prose rules: `writing.instructions.md`.
- **Portable paths:** Never write a machine-specific absolute path or identifier (`/Users/<name>`, hostname, serial, personal email) into a file; use `$HOME`, `~`, `$HOMEBREW_PREFIX`, `$XDG_*`, or a repo-relative path. Hardcoding one requires an explicit ask or user approval.
- **Scope:** Preserve unrelated changes. Do not broaden scope for adjacent work.

## Rule routing

Claude Code and Copilot load matching shared rules automatically. Agents without a scoped rule loader read `behavior.instructions.md` and `engineering.instructions.md` before every task, then the applicable rules:

- UI: `design.instructions.md`.
- React or Next.js: `react.instructions.md`, `vercel-react-best-practices`, and `vercel-composition-patterns` for non-trivial component design.
- TypeScript: `typescript.instructions.md`.
- Animation or motion: `motion.instructions.md` and its routed skills.
- Node.js: `node.instructions.md`.
- Shell scripts: `shell.instructions.md`.
- Bugs, crashes, regressions, or failing tests: `find-root-cause`.
- Human prose beyond a few sentences: `writing.instructions.md` and `humanizer`.
- Agentic docs or skills: `sync-agents`; add `skill-creator` when creating or changing a skill.
- Library, framework, or API questions: `context7-mcp`.
- Browser work or real UI verification: `browser.instructions.md` and `agent-browser`.
- `$HOME` dotfiles: `dotfiles.instructions.md`, which routes its scoped companion rules.

Shared sources are under `~/.agents/`; provider entrypoints link there and are not edit targets. Do not duplicate these instructions.

## Environment and tools

- macOS on Apple Silicon; Homebrew is `/opt/homebrew`; use VS Code and Ghostty.
- Project code lives under `~/Developer`; `$HOME` is the dotfiles git repository.
- Keep personal, work, and client contexts separate; target browser, email, and calendar work only at the active context's account and Chrome window. Client projects are under `~/Developer/@<client>`; identity overrides are in untracked `~/.gitconfig`.
- The Obsidian vault is `~/.vault`, a tracked symlink into its iCloud container. Always reference the vault through `~/.vault`; never write its resolved iCloud path.
- zsh uses custom plugins and themes under `~/.zsh`. Check the matching plugin before treating commands such as `profile`, `plugin`, `brew`, `mas`, `lts`, `deps`, or `dotfiles` as binaries.
- Node uses `nodenv`; Python uses `pyenv`; Ruby uses `rbenv`. Do not introduce any other runtime or version manager unless asked.
- The default Node package manager is pnpm through Corepack. Respect the project's lockfile when it selects npm or a different package manager. Use the version-manager shims, not system runtimes.

## Git

- Commits are signed with the local SSH key through git's default `ssh-keygen` signer. Never disable signing or use `--no-gpg-sign`.
- Follow the target repository's commit conventions. Do not add AI attribution or `Co-authored-by` trailers.
- `$HOME` types and scopes are in `dotfiles.instructions.md`.

## Generated files

- Put scratch scripts, logs, and data in the session scratchpad or system temp directory, never a repository.
- Put reusable agent artifacts under an existing agentic folder's `artifacts/` directory, preferring the agent's non-symlinked folder, then `.agents/`. If none exists, follow the repository or user destination instead of creating one.

## Formatting

Repository configuration owns formatting: oxfmt for JS, TS, CSS, and JSON; RuboCop for Ruby; shfmt and shellcheck for shell; `.editorconfig` otherwise. Always run the configured formatter and avoid unrelated changes.
