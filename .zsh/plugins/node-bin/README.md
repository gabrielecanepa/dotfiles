# node-bin plugin

Keeps the nearest project's `node_modules/.bin` on `PATH`.

To use it, add `node-bin` to the plugins array in your zshrc file:

```zsh
plugins=(... node-bin)
```

## Usage

The plugin defines no commands. On every directory change it walks up from the cwd and appends the first `node_modules/.bin` it finds to `PATH`, replacing the entry from the previous directory. The entry is appended, so project binaries never shadow system commands.
