if status is-interactive
    # Commands to run in interactive sessions can go here
end

set -gx EDITOR nvim

fzf_configure_bindings --git_status --history=\cr --variables --directory=\co --git_log=\cg


# TODO: Clean this up
# https://github.com/jarun/nnn/blob/master/misc/quitcd/quitcd.fish
# Rename this file to match the name of the function
# e.g. ~/.config/fish/functions/n.fish
# or, add the lines to the 'config.fish' file.

function n --wraps nnn --description 'support nnn quit and change directory'
    # Block nesting of nnn in subshells
    if test -n "$NNNLVL"
        if [ (expr $NNNLVL + 0) -ge 1 ]
            echo "nnn is already running"
            return
        end
    end

    # The behaviour is set to cd on quit (nnn checks if NNN_TMPFILE is set)
    # To cd on quit only on ^G, remove the "-x" as in:
    #    set NNN_TMPFILE "$XDG_CONFIG_HOME/nnn/.lastd"
    #    (or, to a custom path: set NNN_TMPFILE "/tmp/.lastd")
    # or, export NNN_TMPFILE after nnn invocation
    if test -n "$XDG_CONFIG_HOME"
        set NNN_TMPFILE "$XDG_CONFIG_HOME/nnn/.lastd"
    else
        set NNN_TMPFILE "$HOME/.config/nnn/.lastd"
    end

    # Unmask ^Q (, ^V etc.) (if required, see `stty -a`) to Quit nnn
    # stty start undef
    # stty stop undef
    # stty lwrap undef
    # stty lnext undef

    nnn $argv

    if test -e $NNN_TMPFILE
        source $NNN_TMPFILE
        rm $NNN_TMPFILE
    end
end

