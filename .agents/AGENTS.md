# AGENTS.md

Machine-wide instructions for all coding agents (Claude Code, Codex, Copilot). Applies in **every** project; it holds only what is true everywhere.

## Working principles

The full baseline lives in the always-on rules: `behavior.instructions.md` (reasoning, feedback, chat-output brevity) and `engineering.instructions.md` (simplicity, surgical diffs, verification, the commit workflow). Claude Code and Copilot auto-load both every session; Codex must read both before starting any task. Two hard boundaries bear restating:

- **Version control**: NEVER run `git commit` or `git push` unless the prompt explicitly asks. Writing, fixing, or "applying" changes is NOT a request to commit; leave the result in the working tree and end with the `### Changes` list and commit-message offer (exact format in the engineering rule).
- **Writing**: never use an em-dash or en-dash in any committed file, this repo's own docs included; the sole exception is live chat output. Rewrite with a period, comma, colon, hyphen, or parentheses (see the writing rule).
- **Skill routing (by intent, decided before you start; this is the trigger for Codex and for greenfield work, since the file-scoped rules won't have loaded yet):**
  - Building or restyling **any UI** → open the `design` rule; base is `frontend-design` plus one flavor (default `design-taste-frontend`).
  - Writing or reviewing **React/Next.js code** → open the `react` rule; `vercel-react-best-practices` is the performance bar and `vercel-composition-patterns` drives component design.
  - Writing **Node.js server-side code** (APIs, services, CLIs, scripts) → open the `node` rule.
  - Writing **human-facing prose** longer than a few sentences (docs, README, release notes, marketing copy) → open the `writing` rule and run the `humanizer` skill.
  - Library / API / framework questions → `context7-mcp`. Driving or QA-ing a real web UI → open the `browser` rule (reuse the running dev-server port via `agent-browser`; never spawn an ad-hoc preview server).
  - Editing this machine's dotfiles → the `dotfiles` rule (Codex: read `.agents/rules/dotfiles.instructions.md` first).

## Rules & loading

This file loads globally via:

- **Claude Code**: `~/.claude/CLAUDE.md` symlinks here (user memory, every session).
- **Codex**: `~/.codex/AGENTS.md` symlinks here (top of the global instruction chain).
- **Copilot**: `COPILOT_CUSTOM_INSTRUCTIONS_DIRS=$HOME/.agents` (CLI loads this file and the rules); in VS Code the rules load through `.github/instructions` (see the dotfiles rule for why the `~/.copilot/instructions` default is disabled).

Companion rules live in `.agents/rules/` (auto-loaded; don't duplicate their content here):

- `behavior.instructions.md`: tone, reasoning, feedback, decision-making, chat-output brevity. **Always-on.**
- `engineering.instructions.md`: code-execution discipline (simplicity, surgical diffs, verification) for any repo. **Always-on.**
- `browser.instructions.md`: real-browser work; reuse the running dev-server port, drive it through `agent-browser`, clean up on completion. **Always-on** (browser work is an action, not a file edit). Routes to the `agent-browser` skill.
- `writing.instructions.md`: human-facing prose; routes to the `humanizer` skill. **Loads for docs/markdown/prose.**
- `design.instructions.md`: UI/visual work; routes to the design skills. **Loads for frontend files.**
- `typescript.instructions.md`: language-level TS idioms (guard clauses, arrow functions, interface over type, inline type imports, alias imports) and the framework-docs-first rule. **Loads for `.ts`/`.tsx` files.**
- `react.instructions.md`: prop forwarding, composition over boolean props, JSX idioms, the shared->features->app boundary, Next.js `app/` placement; routes to the React perf and composition skills. **Loads for `.jsx`/`.tsx` files.**
- `node.instructions.md`: Node.js runtime discipline (event loop, streams, errors and shutdown, diagnostics, packaging). **Loads for server-side JS/TS paths.**
- `dotfiles.instructions.md`: conventions for the `$HOME` dotfiles repo. **Loads only when editing this machine's config** (shell, git, brew, git hooks, agent config).

Claude Code and Copilot load these rule files automatically (Claude Code loads always-on ones every session and path-scoped ones when a touched file matches; Copilot scopes via `applyTo`). **Codex does not**: when a task involves code, prose, UI, driving a browser, or this machine's dotfiles, read the relevant `.agents/rules/*.instructions.md` file before starting.

## Environment

- **Machine:** macOS, Apple Silicon (arm64). Homebrew prefix `/opt/homebrew`.
- **Editor:** VS Code (`EDITOR=code`, `GIT_EDITOR="code --wait"`).
- **Terminal:** Ghostty.
- **Project workspace:** `$WORKING_DIR` = `~/Developer` (jump with `cdw`); real project code lives there. `$HOME` itself is a git repo (dotfiles); see the dotfiles rule when working under `~`.

## Obsidian vaults

- **Vaults live only in Obsidian's iCloud container** `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/`, one per top-level folder, synced across devices. Read vaults only from there; never `~/Documents`, `~/iCloud Drive`, or a hardcoded path.
- The `obsidian-vaults` MCP server (`@modelcontextprotocol/server-filesystem`, user scope) grants read/write over specific vault paths for clients without native file access (mainly Claude Desktop); Claude Code uses its own file tools.

## Shell

- **zsh + oh-my-zsh** with a custom framework under `ZSH_CUSTOM=~/.zsh`. Many "commands" are custom functions/plugins, not binaries (`profile`, `plugin`, the `brew`/`mas` wrapper, `lts`, `completions`, `deps`, `dotfiles`, etc.); check `.zsh/plugins/<name>/` before assuming a command is a system tool. The `dotfiles` plugin (`dotfiles init` to fix drift, `dotfiles doctor` to report it) re-links managed symlinks that apps clobber.
- The `brew`/`mas` commands are **wrapped** (in the `brewfile` plugin): `brew dump` writes the Brewfile, `brew global` installs from it, `brew fresh` updates+upgrades+cleanup+dump+doctor.

## Toolchains (version managers, NOT mise/asdf/nvm)

- **Node:** `nodenv` (pinned in `.node-version`). **Default package manager: `pnpm`**, provided by Corepack (which ships with Node); use it for all generated install/run/exec commands (`pn`=`pnpm`, `pnx`=`pnpx`). A nodenv install hook runs `corepack enable` on every new Node version, so pnpm follows the active Node. `npm` comes with Node; `bun` and `deno` are installed via Homebrew (not as Node globals); only use them when a project's lockfile/config calls for it (`bun.lockb`→bun, `package-lock.json`→npm).
- **Python:** `pyenv` (`.python-version`). **Ruby:** `rbenv` + `ruby-build` (`.ruby-version`).
- Shims are on PATH; don't invoke system `python3`/`ruby`/`node` directly. Don't introduce `mise`/`asdf`/`nvm`/`volta` unless explicitly asked.

## Git & commits

- **Committing requires an explicit ask** (the Version control principle above; exact offer format in the engineering rule). The rules below describe HOW to commit once the user has asked, not permission to commit on your own.
- **Commits are signed** via the 1Password SSH agent (`gpg.format=ssh`, `commit.gpgsign=true`, signer `op-ssh-sign`). Never disable signing or add `--no-gpg-sign`.
- **No `Co-authored-by` / AI trailers** (VS Code GitLens `git.addAICoAuthor` is `off` in `.vscode/user/settings.json`). Single-line messages unless a `BREAKING CHANGE:` footer is needed.
- **Conventional commits, match the repo you're in.** Commit types are per-repo (the dotfiles repo uses a non-standard set; see its rule). `pull.rebase=true`, `push.autoSetupRemote=true`, `init.defaultBranch=main`.

## Generated files

Applies to **every** agent (Claude, Claude Code, Codex, Copilot) generating any file.

- **Throwaway files** (one-shot scripts, logs, scratch data) go to the agent's session scratchpad or the system temp dir, **never into the repo**.
- **Artifacts** stay useful after the session (reusable scripts, audit/eval results, HTML previews, visual assets). In a project that already has an agentic folder (`.agents/`, `.claude/`, `.codex/`, etc.), they go in `<agent-folder>/artifacts/` with a unique descriptive name; `<agent-folder>` is the agent's own non-symlinked folder if present, else `.agents/`. No agentic folder, don't create one; place the deliverable where the user or repo convention says. The `$HOME` dotfiles repo has its own variant (see the dotfiles rule).
- **Ignore on first write.** When first creating `artifacts/`, git-ignore it (root `.gitignore` or `<agent-folder>/.gitignore`).

## Formatting & linting (respect existing config; don't reformat to your own style)

- **JS/TS/CSS/JSON:** `oxfmt` (`.oxfmtrc.json`). **Ruby:** `rubocop` (`.rubocop.yml`). **Shell:** `shfmt` + `shellcheck` (`.shellcheckrc`); shfmt options live in `.editorconfig` `[[shell]]`/`[[bash]]`, zsh is excluded and never formatted. **All files:** `.editorconfig`.
- Run the tool; the config files own the style values. Never hand-match style or reformat beyond your change. (In Claude Code the `format-edited-file` PostToolUse hook runs the right formatter automatically.)
