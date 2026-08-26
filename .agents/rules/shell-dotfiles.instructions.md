---
description: 'Use for shell and package internals in the $HOME dotfiles repository: startup order, zsh plugins, Git hooks and config, Homebrew, npm globals, VS Code extensions, runtimes, and dotfiles reconciliation.'
applyTo: '.config/git/**,.config/nodenv/**,.homebrew/**,.npm/**,.vscode/extensions.json,.zsh/**,.aliases,.bash_profile,.bashrc,.gemrc,.gitconfig,.install.sh,.macos,.node-version,.npmrc,.profile,.python-version,.ruby-version,.shellcheckrc,.zprofile,.zshenv,.zshrc'
paths:
  - '.config/git/**'
  - '.config/nodenv/**'
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
  - '.node-version'
  - '.npmrc'
  - '.profile'
  - '.python-version'
  - '.ruby-version'
  - '.shellcheckrc'
  - '.zprofile'
  - '.zshenv'
  - '.zshrc'
---

# Shell dotfiles

These rules apply only when `$HOME` is the active repository.

## Startup and plugins

- Startup order is `.zshenv` for environment and PATH, generated `.zprofile`, then `.zshrc` for Oh My Zsh, plugins, completions, and `dotfiles init`, which reruns `initialize-path` and sources the aliases file. The `profile` plugin owns `.zprofile`; never edit it directly.
- zsh plugins log through `_zsh::log <error|warn|success|info> <plugin> <text>` from the first-loaded `logger` plugin. Consumers retain the small fallback needed to work standalone; do not emit diagnostics with raw `print` or `echo`.
- `dotfiles init` finishes shell startup and reconciles user-owned machine state without deleting third-party state. Keep it idempotent. `.install.sh` owns first-machine bootstrap and may prompt or use `sudo` for explicit system setup.
- `dotfiles init` owns the untracked `~/.vault` symlink: it links to the iCloud Obsidian folder whose name matches `$OBSIDIAN_VAULT`, reports a missing folder or a real `~/.vault` directory, and does nothing when the variable is unset. Its resolver holds the only copy of the container path.

## Plugin and theme format

- Custom plugins in `.zsh/plugins/<name>/` mirror the oh-my-zsh plugin layout: `<name>.plugin.zsh`, a `README.md`, a `_<command>` completion file for each user-facing command with completable arguments, and supporting scripts resolved through `${0:A:h}`.
- Plugin and completion files have no file header or comments beyond the required `#compdef` line, except rare concise explanations on non-obvious lines. Supporting scripts open with a short comment header. The `README.md` owns description, usage, and settings in the exact oh-my-zsh format; use the existing custom plugins as reference.
- Extract logic into a supporting script only when it concretely pays off in performance or code quality; otherwise keep it inline in the plugin file.
- Custom themes in `.zsh/themes/` are a single `<name>.zsh-theme` file with no README, opened by a short description-only comment header, with user settings as `ZSH_THEME_<NAME>_*` variables at the top. Shared segments live in `.zsh/themes/lib/` and are sourced through `${0:A:h}/lib/<file>.zsh`.

## Git

- The `$HOME` repository uses its local `.config/git/hooks`: `commit-msg` runs commitlint; `pre-push` reruns commitlint plus shellcheck, shfmt, oxfmt, and portability checks. Do not introduce Husky, a global `core.hooksPath`, or `init.templateDir`.
- Shared Git settings live in tracked `.config/git/config`. Ignored `~/.gitconfig` wins later and owns identity, signing key, editor, and client overrides. Never track an email, key, or machine path.

## Package ownership

- `.homebrew/Brewfile` owns applications and shell tooling, including shellcheck and shfmt. Do not install Node-based tools with Homebrew because its formulas introduce a second Node runtime.
- `.npm/package.json` owns global Node tools. The `npm-global` plugin refreshes it synchronously and offline after mutating global commands, and the nodenv install hook restores it for each Node version. Corepack owns pnpm.
- `.vscode/extensions.json` is the single wanted set of VS Code extensions. Add only published marketplace IDs; `dotfiles init` installs recommendations that are missing locally.
- nodenv, pyenv, and rbenv own their runtimes. Use their shims and version files; do not add another version manager.
