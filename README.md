# Config Repository

This repository contains installation instructions, configuration files
("dotfiles") for different programs such as git, vim etc.

## Notes

The notes folder contain instructions and other documentation for useful
applications.


## dotfiles

The dotfiles folder contain the actual configuration files for different
applications. Stow is used to deploy the configuration files to their correct
locations. See dotfiles/README.md for more information.


## Workstation Preparations

Make sure that `$HOME/.local/bin` is in the $PATH. See
https://www.freedesktop.org/software/systemd/man/file-hierarchy.html#Home%20Directory
for more information. On Ubuntu (bash), this is configured by default in
`.profile`.

TODO: Add `fzf` and add links to other tools.

## Compositor

The window manager i3 requires a compositor in order for scrolling to look nice.
For this purpose, `picom` is recommended. Install using:

`sudo pacman -Syu picom`


## Login

By default, EndeavourOS uses LightDM for the log-in, and uses the lightdm-gtk-greeter.



## Utilities

### Ripgrep

Ubuntu: `sudo apt install ripgrep`

Arch: `sudo pacman -Syu ripgrep`

See https://github.com/BurntSushi/ripgrep for more information.


### Fd Find

```
sudo apt install fd-find
ln -s $(which fdfind) ~/.local/bin/fd
```

Arch: `sudo pacman -Syu fd`

See https://github.com/sharkdp/fd#installation for more information.


### Terminal File Browser

Arch: `sudo pacman -Syu lf`

Arch: `sudo pacman -Syu ranger`


## Stow

Stow is used to manage the dotfiles. See https://www.gnu.org/software/stow/ for
detatils. Install using

Ubuntu: `sudo apt install stow`

Arch: `sudo pacman -Syu stow`

### Manage config files with stow

The command `stow` is used to manage the config files in this directory. The
command will create a symlink in the target directory that points to the config
files in this repository. This makes it easy to handle changes (using git diff)
and updates.

### Stow a configuration

The following command is used to stow a configuration.

`stow <application-name> -t <target-dir>`

The command will create a symlink in the target-dir named according to the
application-name. The symlink will point to the contents of the
application-name directory.

For example, to stow the i3 configuration, the command

`stow i3 -t ~`

To stow individual files that are not stored in .config (such as .gitconfig),
use the flag `--dotfiles`.

`stow gitconfig --dotfiles -t ~`

### Unstow

To unstow an application, use the following command

`stow -t <target-dir> -D <application-name>`

For the i3 configuration, the command would be

`stow -t ~ -D i3`


## Build tools

Quite a few tools are needed for the LSP in nvim to work properly.

```
sudo apt install npm
sudo apt install python3.10-venv
sudo apt install unzip
sudo apt install clang clangd
sudo apt install make
```


## Configure SSH

In order to clone the config repo using ssh, the ssh client must be setup
properly and include valid ssh keys. A guide is available at github
(https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent).

1. Create a new ssh keypair

`ssh-keygen -t ed25519 -C "blue.zephyr.git@gmail.com"`

Call the key something as `id_github_<host>`, where <host> is something . Move
the keys to the .ssh folder.

2. Start the ssh agent and add the key

```
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/<private key>
```

3. Add the public key to github

Navigate to https://github.com/settings/keys and click the 'New SSH key'
button. Enter a name for the key such as "BlueZephyr <host>". Use

`cat ~.ssh/id_github_<host>.pub`

and copy the output into the Key part. Press "Add SSH key" to save.

## Blue Zephyr

Color: R: 91 G: 102 B: 118
