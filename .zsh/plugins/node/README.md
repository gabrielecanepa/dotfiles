# node plugin

Prints or pins the running Node.js version and keeps the nearest project's `node_modules/.bin` on `PATH`.

To use it, add `node` to the plugins array in your zshrc file:

```zsh
plugins=(... node)
```

## Usage

```zsh
node-version       # print the running version (without the leading v)
node-version dump  # write it to ./.node-version
```

On every directory change the plugin walks up from the cwd and appends the first `node_modules/.bin` it finds to `PATH`, replacing the entry from the previous directory. The entry is appended, so project binaries never shadow system commands.
