# runtimes plugin

Adds shell integration, completions, and faster startup to [nodenv](https://github.com/nodenv/nodenv), [pyenv](https://github.com/pyenv/pyenv), and [rbenv](https://github.com/rbenv/rbenv). It can be used as a replacement for each version manager's default Oh My Zsh plugin.

To use it, add `runtimes` to the plugins array in your zshrc file:

```zsh
plugins=(... runtimes)
```

## Usage

The plugin defines no commands. For each manager, it exports `<MANAGER>_SHELL=zsh`, defines the shell wrapper function, and sources the completion.

The wrapper routes the shell subcommands through `eval "$(<manager> sh-<command>)"` and sends everything else to the binary. `.zshenv` adds each manager's `$<MANAGER>_ROOT/shims` directory to `PATH`, falling back to `$HOME/.<manager>/shims`.

Replacing `eval "$(<manager> init - --no-rehash zsh)"` removes 3 startup subprocesses per manager. The globs that replace them cost under a millisecond for all three.

## Settings

- `ZSH_RUNTIME_MANAGERS`: version managers to wrap and add to `PATH` from `.zshenv`, in order. Defaults to `(nodenv pyenv rbenv)`.
