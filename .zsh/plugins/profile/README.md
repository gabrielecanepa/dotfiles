# profile plugin

Manages the shell profile (name, email, working directory, editor): install, configure, store it in `~/.zprofile`, and sync into the Git config.

To use it, add `profile` to the plugins array in your zshrc file:

```zsh
plugins=(... profile)
```

## Usage

| Command                | Description                                                |
| ---------------------- | ---------------------------------------------------------- |
| `profile`              | Print the current profile                                  |
| `profile install`, `i` | Install a new profile                                      |
| `profile config`       | Edit the current profile                                   |
| `profile reload`       | Rewrite the exports and Git config from the current values |
| `profile check`        | Check that the profile is installed correctly              |
| `profile help`         | Show the help message                                      |

The default output has the following format:

```console
$ profile
user    john.doe
name    John Doe
email   john@doe.com
path    ~/Developer
editor  Visual Studio Code
```

The exported variables are written between `# BEGIN PROFILE` and `# END PROFILE` markers in `~/.zprofile`; content outside the block is preserved.

## Settings

- `ZSH_PROFILE_SEPARATOR`: separator for the profile output. Defaults to four spaces.
- `ZSH_GIT_CONFIG`: Git config file where the identity values (`user.name`, `user.email`, `core.editor`) are written. When unset, the plugin writes to the global Git configuration.
