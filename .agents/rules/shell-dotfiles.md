---
description: 'Use for shell and package internals in the $HOME dotfiles: startup order, zsh plugins and themes, Git hooks and config, Homebrew, npm globals, VS Code extensions, and runtimes.'
applyTo: '.config/git/**,.nodenv/nodenv.d/**,.homebrew/**,.npm/**,.vscode/extensions.json,.zsh/**,.aliases,.bash_profile,.bashrc,.gemrc,.gitconfig,.install.sh,.npmrc,.profile,.shellcheckrc,.zprofile,.zshenv,.zshrc'
paths:
  - '.config/git/**'
  - '.nodenv/nodenv.d/**'
  - '.homebrew/**'
  - '.npm/**'
  - '.vscode/extensions.json'
  - '.zsh/**'
  - '.aliases'
  - '.bash_profile'
  - '.bashrc'
  - '.gemrc'
  - '.gitconfig'
  - '.install.sh'
  - '.macos'
  - '.npmrc'
  - '.profile'
  - '.shellcheckrc'
  - '.zprofile'
  - '.zshenv'
  - '.zshrc'
---

# Shell dotfiles

These rules apply only when `$HOME` is the active repository.

## Startup

- Startup order: `.zshenv` for environment and PATH, the generated `.zprofile`, then `.zshrc` for plugins, completions, and `dotfiles init`.
- `dotfiles init` reruns `initialize-path`, sources the aliases file, and reconciles user-owned machine state without deleting third-party state.
- Keep `dotfiles init` idempotent.
- `init` and `doctor` walk `ZSH_DOTFILES_RECONCILERS` and call `_<name>_reconcile` and `_<name>_drift`, with every hyphen in the name replaced by an underscore.
- `_<name>_drift` prints one `<state> <item>` line per problem; `_<name>_reconcile [verbose]` fixes what it can and logs through `_zsh::log`.
- Defining only the drift half makes a check report-only, which is how a check too slow for shell startup stays out of it.
- A reconciler whose tool already owns a plugin lives in that plugin; one with no shell-facing command is a supporting script in `.zsh/plugins/dotfiles/reconcilers/`.
- The `profile` plugin owns `.zprofile`; never edit it directly.
- `.install.sh` owns first-machine bootstrap and may prompt or use `sudo` for explicit system setup.
- The `profile` plugin owns the untracked `~/.vault` symlink; with `VAULT_DIR` set it links the folder at load and after `config`, `install`, or `reload`.
- The plugin reports a missing vault folder or a real `~/.vault` directory, and does nothing when `VAULT_DIR` is unset.

## Plugins and themes

- Log from a plugin through `_zsh::log <error|warn|success|info> <plugin> <text>` of the `logger` plugin, never raw `print` or `echo`.
- Keep the small fallback a consumer needs to work standalone.
- Never shell out on the startup path to build static text; `runtimes` defines the nodenv, pyenv, and rbenv wrappers itself.
- A plugin in `.zsh/plugins/<name>/` mirrors the oh-my-zsh layout: `<name>.plugin.zsh`, `README.md`, and a `_<command>` completion file per completable command.
- Resolve supporting scripts through `${0:A:h}`; extract logic into one only when it pays off in performance or code quality.
- Plugin and completion files carry no header or comments beyond the required `#compdef` line, except a rare concise note on a non-obvious line.
- Supporting scripts open with a short comment header; the `README.md` owns description, usage, and settings in the exact oh-my-zsh format.
- A theme is a single `.zsh/themes/<name>.zsh-theme` file with no README, a description-only header, and `ZSH_THEME_<NAME>_*` settings at the top.
- Shared theme segments live in `.zsh/themes/lib/` and load through `${0:A:h}/lib/<file>.zsh`.

## Git

- Git hooks live in `.config/git/hooks`: `commit-msg` runs commitlint; `pre-push` reruns it plus shellcheck, shfmt, oxfmt, and portability checks.
- `core.hooksPath` is set only here through the `includeIf "gitdir:~/.git"` block in `.config/git/config`, which loads `.config/git/home.gitconfig`.
- Never introduce Husky, an unscoped `core.hooksPath`, or `init.templateDir`.
- Shared Git settings live in the tracked `.config/git/config`; the ignored `~/.gitconfig` wins later and owns identity, signing key, and editor.
- Never track an email, key, or machine path.

## Package ownership

- `.homebrew/Brewfile` owns applications and shell tooling, including shellcheck and shfmt.
- Never install Node-based tools with Homebrew, because its formulas introduce a second Node runtime; `agent-browser` is the one exception, per `browser.md`.
- `.npm/package.json` owns global Node tools; the `npm-global` plugin refreshes it synchronously and offline after mutating global commands.
- The nodenv install hook restores the global tools for each Node version; Corepack owns pnpm.
- `.vscode/extensions.json` is the single wanted set of VS Code extensions; add only published marketplace IDs.
- `dotfiles init` installs recommendations that are missing locally through the `vscode` reconciler.
- `brewfile` is report-only: `brew bundle check` is too slow for startup, so `dotfiles doctor` reports Brewfile drift and `brew global install` applies it.
- nodenv, pyenv, and rbenv own their runtimes through their shims; never add another version manager.
- Each manager's global `version` file is machine-local and untracked; `lts install` writes it and no repository file pins a runtime.
