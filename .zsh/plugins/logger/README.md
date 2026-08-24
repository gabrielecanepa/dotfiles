# logger plugin

Provides `_zsh::log`, the shared leveled logger used by the other custom plugins.

To use it, add `logger` to the plugins array in your zshrc file, before any plugin that logs through it:

```zsh
plugins=(... logger)
```

## Usage

```zsh
_zsh::log <error|warn|success|info> <plugin> <text>
```

Messages go to stderr: colored by level when stderr is a TTY, prefixed with a plain-text label otherwise.

Plugins that may load without `logger` should keep the standalone fallback:

```zsh
(( $+functions[_zsh::log] )) || _zsh::log() { print -ru2 -- "$2: $3" }
```
