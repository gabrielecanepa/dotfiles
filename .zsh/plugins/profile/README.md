# profile plugin

Manages the shell profile (name, email, editor, working directory): install, configure, store it in `~/.zprofile`, and sync into the Git config.

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
editor  Visual Studio Code
path    ~/Developer
```

The exported variables are written between `# BEGIN PROFILE` and `# END PROFILE` markers in `~/.zprofile`. Content outside the block is preserved. `PROFILE_EDITOR` stores the selected executable, while `EDITOR`, `VISUAL`, and `GIT_EDITOR` use the blocking command required by graphical editors.

## Settings

- `PROFILE_SEPARATOR`: separator for the profile output. Defaults to four spaces.
- `PROFILE_GIT_CONFIG`: Git configuration file where to write the identity values (`user.name`, `user.email`, `core.editor`). When unset, the plugin writes to the global Git configuration.
