# Kitty

[https://sw.kovidgoyal.net/kitty/](Kitty) is a GPU base terminal emulator.

## Installation

$ curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
$ ln -s ~/.local/kitty.app/bin/kitty ~/.local/bin/

## Desktop icon

Note! In order to use the Vim Kitty navigator plugin, kitty needs to be started
with a set of parameters (see kitty.conf). The desktop file in the dotfiles is
updated with this. Use that one instead of the original file.

### Original desktop file

$ cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/

### Updated file

$ cp ./dotfiles/kitty/kitty.desktop ~/.local/share/applications/

### Update user

$ sed -i "s|Icon=kitty|Icon=/home/$USER/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" ~/.local/share/applications/kitty.desktop

## Fonts and icons

To use JetBrains mono, follow the [installation
instructions](https://www.jetbrains.com/lp/mono/#how-to-install).

To use a font with additional icons, see more information on the [Nerd
Fonts](https://www.nerdfonts.com/) home page. Note that some of this is not
needed when using Kitty since fonts are handled a bit differently. See [Kitty
Fonts](https://sw.kovidgoyal.net/kitty/conf/?highlight=font#fonts) for more
information.


## Themes

There are many different alternatives for themes. Examples below

* https://github.com/craffate/papercolor-kitty

## Plugins

* https://github.com/knubie/vim-kitty-navigator

## Todo

* Add icon and possibility to start from the 'start'-menu

