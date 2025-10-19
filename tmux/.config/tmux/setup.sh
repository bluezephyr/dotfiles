#!/bin/bash
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

# start a server but don't attach to it
tmux start-server

# create a new session but don't attach to it either
tmux new-session -d

# install the plugins
~/.config/tmux/plugins/tpm/scripts/install_plugins.sh

# killing the server is not required, I guess
tmux kill-server
