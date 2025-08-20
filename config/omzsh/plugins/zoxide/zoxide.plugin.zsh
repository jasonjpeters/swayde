command -v zoxide >/dev/null 2>&1 || return

## Source OMZ zoxide plugin
source "$ZSH/plugins/zoxide/zoxide.plugin.zsh"

## Aliases
alias cd="z"
