# Zsh Plugin `profile`

The `plugin` CLI allows you to manage your Zsh profile to automize the setup of your development environment.

It provides commands to install, reload, and check the profile configuration.

The default output has the following format:
```sh
$ profile
user   | john.doe
name   | John Doe
email  | john@doe.com
path   | ~/Developer
editor | Visual Studio Code
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

`PROFILE_SEPARATOR` sets a custom separator for the profile output.
