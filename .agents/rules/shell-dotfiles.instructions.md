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

- Startup order is `.zshenv` for environment and PATH, generated `.zprofile`, `.zshrc` for Oh My Zsh, plugins, completions, and `dotfiles init`, then `.aliases`. The `profile` plugin owns `.zprofile`; never edit it directly.
- zsh plugins log through `_zsh::log <error|warn|success|info> <plugin> <text>` from the first-loaded `logger` plugin. Consumers retain the small fallback needed to work standalone; do not emit diagnostics with raw `print` or `echo`.
- `dotfiles init` reconciles user-owned machine state without deleting third-party state. Keep it idempotent. `.install.sh` owns first-machine bootstrap and may prompt or use `sudo` only for explicit system setup.

## Git

- The `$HOME` repository uses its local `.config/git/hooks`: `commit-msg` runs commitlint; `pre-push` reruns commitlint plus shellcheck, shfmt, oxfmt, and portability checks. Do not introduce Husky, a global `core.hooksPath`, or `init.templateDir`.
- Shared Git settings live in tracked `.config/git/config`. Ignored `~/.gitconfig` wins later and owns identity, signing key, 1Password agent path, editor, and client overrides. Never track an email, key, or machine path.

## Package ownership

- `.homebrew/Brewfile` owns applications and shell tooling, including shellcheck and shfmt. Do not install Node-based tools with Homebrew because its formulas introduce a second Node runtime.
- `.npm/package.json` owns global Node tools. The `npm-global` plugin refreshes it synchronously and offline after mutating global commands, and the nodenv install hook restores it for each Node version. Corepack owns pnpm.
- `.vscode/extensions.json` is the single wanted set of VS Code extensions. Add only published marketplace IDs; `dotfiles init` installs recommendations that are missing locally.
- nodenv, pyenv, and rbenv own their runtimes. Use their shims and version files; do not add another version manager.
