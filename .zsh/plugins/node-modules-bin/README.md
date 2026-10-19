# node-modules-bin plugin

Validates or adds the nearest project's `node_modules/.bin` to `PATH`.

To use it, add `node-modules-bin` to the plugins array in your zshrc file:

```zsh
plugins=(... node-modules-bin)
```

## Usage

The plugin defines no commands. On every directory change, it walks up from the current directory and appends the first `node_modules/.bin` it finds to `PATH`, replacing the entry from the previous directory.
