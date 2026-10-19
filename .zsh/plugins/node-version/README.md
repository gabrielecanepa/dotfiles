# node-version plugin

Prints the running Node.js version or pins a Node.js version.

To use it, add `node-version` to the plugins array in your zshrc file:

```zsh
plugins=(... node-version)
```

## Usage

```zsh
node-version             # print the running version without the leading v
node-version pin         # write the running version to ./.node-version
node-version pin 24.1.0  # write 24.1.0 to ./.node-version
```

An explicit version must use the `X.Y.Z` format, with three numeric components.
Invalid versions return an error without changing `.node-version`.
