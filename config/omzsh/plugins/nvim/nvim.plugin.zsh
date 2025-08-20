command -v nvim >/dev/null 2>&1 || return

## Set preferred editor
if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR="vi"
else
    export EDITOR="nvim"
    export VISUAL="$EDITOR"
fi

## Aliases
alias v="nvim"
alias vi="nvim"
alias vim="nvim"
