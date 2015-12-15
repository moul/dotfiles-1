function __color() {
    case $1 in
    red)
        echo "\[\033[31m\]" ;;
    green)
        echo "\[\033[32m\]" ;;
    yellow)
        echo "\[\033[33m\]" ;;
    blue)
        echo "\[\033[34m\]" ;;
    *)
        echo "\[\033[0m\]" ;;
    esac
}

function __remote_ps1() {
    if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
        echo "$(__color yellow)\h"
    else
        echo "$(__color blue)\h"
    fi
}

function __git_ps1() {
    local PS1_OUTPUT=""
    if [[ -d $(git rev-parse --git-dir 2>/dev/null) ]]; then
        __PS1_GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        if [[ -n ${__PS1_GIT_BRANCH/HEAD} ]]; then
            PS1_OUTPUT="${PS1_OUTPUT}$(__color green)${__PS1_GIT_BRANCH}$(__color) "
        fi
        PS1_OUTPUT="${PS1_OUTPUT}$(git rev-parse --short HEAD 2>/dev/null) "
        if [[ -n $(git status -s 2>/dev/null) ]]; then
            PS1_OUTPUT="${PS1_OUTPUT}$(__color yellow)✗ $(__color)"
        fi
    fi
    echo "$PS1_OUTPUT"

}

function __user_ps1() {
    if [ $EUID = 0 ]; then
        echo "$(__color red)\u$(__color blue)"
    else
        echo "$(__color blue)\u"
    fi
}

function __venv_ps1() {
    if [[ -n $VIRTUAL_ENV ]]; then
        echo "(venv)"
    fi
}
function __set_prompt() {
    EXIT_INFO=$(test $? == 0 && printf "\[\033[34m\]" || printf "\[\033[31m\]$? ")
    PS1="$(__venv_ps1)$(__user_ps1)@$(__remote_ps1)$(__color blue): \w$(__color) $(__git_ps1)${EXIT_INFO}$(__color blue)\$ $(__color)"
}


function viw() {
    vim `which $1`
}

function vd() {
    [ "$1" ] && cd *$1*
}

function repeat() {
    if [ "$1" -eq "$1" ]; then
        while [ -n "$2" ]; do
            eval "$2"
            sleep $1
        done
    fi
}

pssh() {
    # Only supports -l and -A ssh options!
    TEMP=`getopt -o ":l:A" -- "$@"`

    local OPTIND o ssh_cmd ssh_count P_PATH

    ssh_cmd="ssh"

    eval set -- "$TEMP"
    while true; do
        case "$1" in
            -- ) shift; break ;;
            * )
                ssh_cmd="${ssh_cmd} $1"
                shift
                ;;
        esac
    done

    ssh_count=$(wc -w <<< "$@")

    tmux new-window "${ssh_cmd} $1"
    tmux rename-window "pssh (${ssh_count})"
    shift
    while [ $# -gt 0 ]; do
        tmux split-window "${ssh_cmd} $1"
        tmux select-layout tiled > /dev/null
        shift
    done
    tmux select-layout tiled > /dev/null
    tmux set-window-option synchronize-panes on > /dev/null
}

ls --color=auto >/dev/null 2>&1
if [[ $? != 0 ]]; then
    alias ls="ls -GF"
else
    alias ls="ls --color=auto"
fi


PROMPT_COMMAND='__set_prompt'
PS1="${error} ${PS1}"

# misc aliases
alias ll='ls -l'

# git aliases
alias gco='git checkout'
alias gst='git status'
alias grhh='git reset --hard HEAD'
alias ga='git add'
alias gc='git commit'
alias gd='git diff'
alias gdc='git diff --cached'
alias gb='git branch'
alias gl='git log'

# sudo aliases
alias please=sudo
alias fucking=sudo

HISTSIZE=10000
SAVEHIST=10000

export EDITOR=vim
export PAGER=less

SOCK=~/.ssh/ssh_auth_sock
if test $SSH_AUTH_SOCK && [ $SSH_AUTH_SOCK != $SOCK ]
then
    rm -f $SOCK
    ln -sf $SSH_AUTH_SOCK $SOCK
    export SSH_AUTH_SOCK=$SOCK
fi


export RBENV_ROOT="$HOME/.rbenv"
export PYENV_ROOT="$HOME/.pyenv"
if [ -z "$PATH_EXPANDED" ]; then
    PATH="$HOME/bin:$PYENV_ROOT/bin:$RBENV_ROOT/bin:$PATH"
fi

eval "$(pyenv init -)"
eval "$(rbenv init -)"
