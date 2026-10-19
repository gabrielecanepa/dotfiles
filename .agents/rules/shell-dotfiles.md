---
description: "Use for shell and package internals in the $HOME dotfiles: startup order, zsh plugins and themes, Git hooks and config, Homebrew, npm globals, VS Code extensions, and version managers."
applyTo: ".config/macos/**,.config/git/**,.nodenv/nodenv.d/**,.homebrew/**,.npm/**,.vscode/extensions.json,.zsh/**,.bash_profile,.bashrc,.gitconfig,.npmrc,.profile,.shellcheckrc,.zprofile,.zshenv,.zshrc"
paths:
  - ".config/macos/**"
  - ".config/git/**"
  - ".nodenv/nodenv.d/**"
  - ".homebrew/**"
  - ".npm/**"
  - ".vscode/extensions.json"
  - ".zsh/**"
  - ".bash_profile"
  - ".bashrc"
  - ".gitconfig"
  - ".npmrc"
  - ".profile"
  - ".shellcheckrc"
  - ".zprofile"
  - ".zshenv"
  - ".zshrc"
---

# Shell dotfiles

These rules apply only when `$HOME` is the active repository.

## Startup

- `.zshenv` exports shell-independent environment variables without changing PATH.
- `.zprofile` orders login PATH and INFOPATH after macOS `path_helper`.
- `.zshrc` adds Homebrew `fpath` and sources `.zshrc.local` before Oh My Zsh loads its libraries, plugins, completions, custom files, and theme.
- The `launchd` plugin runs its reconciliation worker through `command zsh ... &|`, isolated from the calling shell.
- `LAUNCHD_DIR` selects source plists, defaulting to `${XDG_CONFIG_HOME:-$HOME/.config}/launchd`.
- The worker reconciles plugin-owned links and jobs; `launchd.md` owns the loading and retirement rules.
- `.zprofile` is public and agent-editable; keep machine-specific preferences and secrets in the ignored `.zshrc.local`.
- First-machine setup needs explicit approval; ongoing shell startup never uses `sudo`.

## Plugin output

- Plugins stay silent on successful load and write requested results to stdout.
- Use `print -ru2 -- '<command>: <message>'` for actionable diagnostics.

## Plugins and themes

- A plugin in `.zsh/plugins/<name>/` mirrors the oh-my-zsh layout: `<name>.plugin.zsh`, `README.md`, and a `_<command>` completion file per completable command.
- Top-level `.zsh/*.zsh` files override Oh My Zsh defaults after plugins load; dot-prefixed files there do not load.
- Resolve supporting scripts through `${0:A:h}`; extract logic into one only when it pays off in performance or code quality.
- Plugin and completion files carry no header or comments beyond the required `#compdef` line, except a rare concise note on a non-obvious line.
- Supporting scripts open with a short comment header; the `README.md` owns description, usage, and settings in the exact oh-my-zsh format.
- A theme is a single `.zsh/themes/<name>.zsh-theme` file with no README, a description-only header, and `ZSH_THEME_<NAME>_*` settings at the top.
- A theme is standalone: it never sources another file, so it keeps its own copy of shared code such as the hook cleanup.

## Git

- Git hooks live in `.config/git/hooks`: `commit-msg` runs commitlint; `pre-push` reruns it plus shellcheck, shfmt, oxfmt, and portability checks.
- `core.hooksPath` is set only here through the `includeIf "gitdir:~/.git"` block in `.config/git/config`, which loads `.config/git/home.config`.
- Never introduce Husky, an unscoped `core.hooksPath`, or `init.templateDir`.
- Shared Git settings live in the tracked `.config/git/config`; the ignored `~/.gitconfig` wins later and owns identity, signing key, and editor.
- Never track an email, key, or machine path.

## Package ownership

- `.homebrew/Brewfile` owns applications and shell tooling, including shellcheck and shfmt.
- Never install Node-based tools with Homebrew, because its formulas introduce a second Node runtime; `agent-browser` is the one exception, per `browser.md`.
- `.npm/package.json` owns global Node tools; the `npm-global` plugin refreshes it synchronously and offline after mutating global commands.
- The nodenv install hook restores the global tools for each Node version; Corepack owns pnpm.
- `.vscode/extensions.json` is the single wanted set of VS Code extensions; add only published marketplace IDs.
- `brew check` wraps `brew bundle check --global`; `brew global install` applies the global Brewfile.

## Version managers

- nodenv, pyenv, and rbenv run as plain binaries over the shims on `PATH`; never add another version manager or a shell wrapper function.
- `pyenv shell`, `nodenv shell`, and `rbenv shell` are intentionally unavailable; select a version with `local` or `global` files instead.
- nodenv and rbenv completions load from Homebrew `fpath`; pyenv has no completion, because Homebrew ships it only as a sourced `pyenv.zsh` script.
- Each manager's global `version` file is machine-local and untracked; `lts install` writes it and no repository file pins a runtime.
