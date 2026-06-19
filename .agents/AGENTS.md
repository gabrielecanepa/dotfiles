# AGENTS.md

Machine-wide instructions for all coding agents (Claude Code, Codex, Copilot). Applies in **every** project; it holds only what is true everywhere. Loaded globally via:

- **Claude Code**: `~/.claude/CLAUDE.md` symlinks here (user memory, every session).
- **Codex**: `~/.codex/AGENTS.md` symlinks here (top of the global instruction chain).
- **Copilot**: `COPILOT_CUSTOM_INSTRUCTIONS_DIRS=$HOME/.agents` (CLI loads this file); `~/.copilot/instructions/` loads the rules in VS Code + CLI.

Companion rules live in `.agents/rules/` (auto-loaded; don't duplicate their content here):

- `behavior.instructions.md`: tone, reasoning, feedback, decision-making. **Always-on.**
- `engineering.instructions.md`: code-execution discipline (simplicity, surgical diffs, verification) for any repo. **Always-on.**
- `writing.instructions.md`: human-facing prose; routes to the `humanizer` skill. **Loads for docs/markdown/prose.**
- `design.instructions.md`: UI/visual work; routes to the design skills. **Loads for frontend files.**
- `dotfiles.instructions.md`: conventions for the `$HOME` dotfiles repo. **Loads only when editing this machine's config** (shell, git, brew, git hooks, agent config).

Claude and Copilot load these rule files automatically. **Codex does not**: when a task involves code, prose, UI, or this machine's dotfiles, read the relevant `.agents/rules/*.instructions.md` file before starting.

## Working principles

The non-negotiable baseline for every task; the rule files expand these.

- **Reasoning**: challenge flawed premises; surface assumptions and tradeoffs up front; never fake certainty. In autonomous runs, decide and proceed, hard-stopping only for irreversible or destructive actions.
- **Feedback**: no agreement by default, no softening, no praise-padding; every critique carries a concrete next step.
- **Engineering**: build the minimum that solves the problem; keep diffs surgical (every changed line traces to the request); verify against a machine-checkable criterion, not "it works". **Never add comments to code** (the only exceptions are JSDoc when the codebase already uses it, and strictly necessary linter-disable directives; see the engineering rule).
- **Writing**: never use an em-dash or en-dash in any committed file, this repo's own docs included; the sole exception is live chat output to the user. Rewrite around it with a period, comma, colon, or parentheses (see the writing rule).
- **Version control**: NEVER run `git commit` (or `git push`) unless the prompt explicitly asks you to commit, push, or otherwise persist to git. Making changes, fixing, refactoring, or "applying" something is NOT a request to commit; leave the result staged-or-unstaged in the working tree and stop. When you judge the work is commit-worthy, end your reply by listing the changes, giving the commit message alone in a code block, and asking whether to run the commit (see the engineering rule for the exact format). This is a hard boundary, on par with not running destructive commands unasked.
- **Skill routing (by intent, decided before you start; this is the trigger for Codex and for greenfield work, since the file-scoped rules won't have loaded yet):**
  - Building or restyling **any UI** → open the `design` rule; base is `frontend-design` plus one flavor (default `design-taste-frontend`).
  - Writing **human-facing prose** longer than a few sentences (docs, README, release notes, marketing copy) → open the `writing` rule and run the `humanizer` skill.
  - Library / API / framework questions → `context7-mcp`. Driving or QA-ing a real web UI → `agent-browser`.
  - Editing this machine's dotfiles → the `dotfiles` rule (Codex: read `.agents/rules/dotfiles.instructions.md` first).

## Environment

- **Machine:** macOS, Apple Silicon (arm64). Homebrew prefix `/opt/homebrew`.
- **Editor:** VS Code (`EDITOR=code`, `GIT_EDITOR="code --wait"`). **Terminal:** Ghostty.
- **Project workspace:** `$WORKING_DIR` = `~/Developer` (jump with `cdw`); real project code lives there. `$HOME` itself is a git repo (dotfiles); see the dotfiles rule when working under `~`.

## Shell

- **zsh + oh-my-zsh** with a custom framework under `ZSH_CUSTOM=~/.zsh`. Many "commands" are custom functions/plugins, not binaries (`profile`, `plugin`, the `brew` wrapper, `lts`, `completions`, `deps`, etc.); check `.zsh/plugins/<name>/` before assuming a command is a system tool.
- The `brew` command is **wrapped**: `brew dump` writes the Brewfile, `brew global` installs from it, `brew fresh` updates+upgrades+cleanup+dump+doctor.

## Toolchains (version managers, NOT mise/asdf/nvm)

- **Node:** `nodenv` (pinned in `.node-version`). **Default package manager: `pnpm`**: use it for all generated install/run/exec commands (`pn`=`pnpm`, `pnx`=`pnpx`). `bun`, `npm`, `corepack`, `deno` are also installed; only use them when a project's lockfile/config calls for it (`bun.lockb`→bun, `package-lock.json`→npm).
- **Python:** `pyenv` (`.python-version`). **Ruby:** `rbenv` + `ruby-build` (`.ruby-version`).
- Shims are on PATH; don't invoke system `python3`/`ruby`/`node` directly. Don't introduce `mise`/`asdf`/`nvm`/`volta` unless explicitly asked.

## Git & commits

- **Never commit or push unless the prompt explicitly asks for it** (see the Version control principle above). Default to leaving changes in the working tree and offering the command. The rules below describe HOW to commit once the user has asked, not permission to commit on your own.
- **Commits are signed** via the 1Password SSH agent (`gpg.format=ssh`, `commit.gpgsign=true`, signer `op-ssh-sign`). Never disable signing or add `--no-gpg-sign`.
- **No `Co-authored-by` / AI trailers** (`git.addAICoAuthor=off`). Single-line messages unless a `BREAKING CHANGE:` footer is needed.
- **Conventional commits, match the repo you're in.** Commit types are per-repo (the dotfiles repo uses a non-standard set; see its rule). `pull.rebase=true`, `push.autoSetupRemote=true`, `init.defaultBranch=main`.
- **Rich git aliases exist, prefer them** (`.gitconfig`, also exposed as `g<alias>` shell aliases): `gst`, `gacm`, `gcm`, `gco`, `glg`, `gsweep`, `gfps`, `gpristine`, `gredo`, `gundo`. Run `git aliases` to list all.

## Formatting & linting (respect existing config; don't reformat to your own style)

- **JS/TS/CSS/JSON:** `oxfmt` (`.oxfmtrc.json`): no semicolons, single quotes (double in CSS), `es5` trailing commas, avoid arrow parens; imports non-relative.
- **Ruby:** `rubocop` (`.rubocop.yml`): double-quoted strings, line length 120, `NewCops: enable`.
- **Shell:** `shellcheck` (`.shellcheckrc`).
- **All files:** `.editorconfig`: UTF-8, LF, 2-space indent, final newline, trim trailing whitespace, max line 120.
- **Prefer existing aliases/functions over raw commands**: `.aliases` and the git aliases are curated; use `gst`, `pn`, `cdw`, `brew fresh`, etc.
