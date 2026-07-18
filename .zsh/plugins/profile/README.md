# Zsh Plugin `profile`

The `profile` command lets you manage your Zsh profile to automate the setup of your development environment.

It provides commands to install, reload, and check the profile configuration.

The default output has the following format:

```sh
$ profile
user    john.doe
name    John Doe
email   john@doe.com
path    ~/Developer
editor  Zed
```

## Usage

```shell
profile                    # Print the current profile
profile install, i         # Install a new profile
profile config             # Configure the profile
profile reload             # Reload the current profile
profile check              # Check if the profile is installed correctly
profile help, -h, --help   # Print help message
```

## Options

### Separator

`ZSH_PROFILE_SEPARATOR` sets a custom separator for the profile output. It defaults to four spaces.

### Git config file

`ZSH_GIT_CONFIG` sets the git config file where the identity values (`user.name`, `user.email`, `core.editor`) are written. When unset, the plugin writes to the global git configuration (`git config --global`). Point it at an untracked file, such as the root `~/.gitconfig` when your tracked global config lives at `~/.config/git/config`, so identity never lands in a dotfiles repository.
