#!/bin/bash
# See https://unix.stackexchange.com/questions/132065/how-do-i-get-ssh-agent-to-work-in-all-terminals/132117#132117

# set SSH_AUTH_SOCK env var to a fixed value
export SSH_AUTH_SOCK=~/.ssh/ssh-agent.$HOSTNAME.sock

# test whether $SSH_AUTH_SOCK is valid
ssh-add -l 2>/dev/null >/dev/null

# If not valid, then start ssh-agent using $SSH_AUTH_SOCK
# and add all existing keys to the agent
if [[ $? -ge 2 ]]; then
    ssh-agent -a "$SSH_AUTH_SOCK" >/dev/null
    rg -l "PRIVATE" ~/.ssh/ | xargs ssh-add
fi

# Add something like the below to the .profile file
# if [[ -f "$HOME/.local/scripts/start-ssh-agent.sh" ]]; then
#     $HOME/.local/scripts/start-ssh-agent.sh
#     export SSH_AUTH_SOCK=~/.ssh/ssh-agent.$HOSTNAME.sock
# i
#
