# Dotfiles Repository

This repository contains installation instructions, configuration files
("dotfiles") for different programs such as git, vim etc.

The different folders contain the actual configuration files for applications.
Stow is used to deploy the configuration files to their correct locations.
See the stow section below for more information.


## Workstation Preparations

Make sure that `$HOME/.local/bin` is in the $PATH. See
https://www.freedesktop.org/software/systemd/man/file-hierarchy.html#Home%20Directory
for more information. On Ubuntu (bash), this is configured by default in
`.profile`.

TODO: Add `fzf` and add links to other tools.

## i3

### Compositor

The window manager i3 requires a compositor in order for scrolling to look nice.
For this purpose, `picom` is recommended. Install using:

`sudo pacman -Syu picom`

### Keymap

To use a keyboard map with international layout without dead keys (US
International without dead keys) on X11, use the following command:

`setxkbmap -layout us -variant altgr-intl -option nodeadkeys`

### Monitors

The utility `autorandr` can be used to automatically select a display
configuration based on connected devices. Install using:

```
yay -S autorandr
```

Configuration files are stored in `.config/autorandr`. To create a new
configuration, start by setting it up using ARandR. Then save the configuration
using `autorandr -s <config-name>`.

Autorandr is executed automatically when monitors are plugged in/unplugged but
in order to have it run also when the laptop lid is opened/closed, this must be
monitored separatedly. One way to do it is using ACPI. Install `acpid` using:

```
yay -S acpid
```

Copy the `~/dotfiles/scripts/autorandr.sh` script to `/etc/acpi/` and modify
the `handler.sh` script in `/etc/acpi` by adding a call to
`/etc/acpi/autorandr.sh` when the lid is opened/closed. Make sure that the
scripts are executable and that the acpid service is enabled:

```
sudo chmod a+c /etc/acpi/autorandr.sh
sudo systemctl enable --now acpid
```

### Polybar

Polybar is a status bar for i3. Install using

```
yay polybar
```

The configuration is in `.config/polybar`.

### Scratchpads

A script (`scratchpad-kitty.sh`) to show a scratchpad with a kitty terminal
running tmux is written based on information here:
https://www.reddit.com/r/i3wm/comments/kjendc/scratchpad/

The script requires `xdotool`. Install using

```
yay xdotool
```


## Hyprland

Hyprland is a tiling window manager for Wayland. Install with `yay`. Also
install additional software to get some useful things. See
https://wiki.hyprland.org/Useful-Utilities/Must-have/ for more information.

```
yay -S dunst
yay -S waybar
yay -S playerctl
yay -S pamixer
yay -S blueman
yay -S hyprpaper
```

## Fonts

`yay -S ttf-jetbrains-mono-nerd`

## Login

By default, EndeavourOS uses LightDM for the log-in, and uses the lightdm-gtk-greeter.

## Default Applications

`xdg-settings get default-web-browser` will return the current default browser.
To change to Chrome, use `set` and application `google-chrome.desktop`. If the
environment variable `BROWSER` is set, it needs to be unset using `unset
BROWSER`.

Changes to default applications will be seen in `~/.config/mimeapps.list`.
Applications can be found in the folder `/usr/share/applications`


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

### Starship

Cross-shell prompt. See https://starship.rs/ Install using:

`curl -sS https://starship.rs/install.sh | sh`

### Neovim

Use the steps below to install on Linux.
See https://github.com/neovim/neovim/wiki/Installing-Neovim#linux
for more information.

```
cd ~/.local/bin
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
chmod u+x nvim.appimage
mv nvim.appimage nvim
```

The setup and configuration for Neovim requires that the following is installed

* Node.js and npm

In order to use the clipboard, a clipboard provider must be available. For X11,
`xclip` can be used.

```
sudo pacman -Syu xclip
```

### Node.js

Install Nodejs and npm using the command below (https://nodejs.org/en/download/package-manager#arch-linux).
See https://nodejs.org/en/about and https://github.com/npm/cli for more
information.

`sudo pacman -Syu nodejs npm`


### Lazygit

(Lazygit)[https://github.com/jesseduffield/lazygit] is a terminal gui git tool.

Use the following steps to install on Ubuntu:

```
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
install lazygit ~/.local/bin
```

### Tokei

Program that displays statistics about code (number of lines, comments, etc)
grouped by language. Install using cargo. See
https://github.com/XAMPPRocky/tokei for more information.

`cargo install tokei`


### Spotify

`sudo pacman -Syu spotify-launcher`

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

`stow -t ~ i3`

To stow individual files that are not stored in .config (such as .gitconfig),
use the flag `--dotfiles`.

`stow --dotfiles -t ~ gitconfig`

### Unstow

To unstow an application, use the following command

`stow -t <target-dir> -D <application-name>`

For the i3 configuration, the command would be

`stow -t ~ -D i3`

### Restow

Restow (first unstow, then stow again) the package names that follow this
option. This is useful for pruning obsolete symlinks from the target tree after
updating the software in a package. This option may be repeated any number of
times.

`stow -R i3`

### Stow Steps

If the dotfiles repo is cloned to the home directory, the -t flag can
be omitted in the commands since the target dir defaults to the parent.
The commands to run can be simplified as below.

```
cd ~
git clone git@github.com:bluezephyr/dotfiles.git
cd dotfiles
stow --dotfiles bash
stow --dotfiles gitconfig
stow i3
stow hypr
stow kitty
stow nvim
stow dunst
stow ranger
```

## Build tools

Tools for programming.

```
sudo apt install clang clangd
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

