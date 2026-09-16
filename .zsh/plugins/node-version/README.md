# node-version plugin

Prints or pins the running Node.js version.

To use it, add `node-version` to the plugins array in your zshrc file:

```zsh
plugins=(... node-version)
```

## Usage

```zsh
node-version       # print the running version (without the leading v)
node-version dump  # write it to ./.node-version
```
