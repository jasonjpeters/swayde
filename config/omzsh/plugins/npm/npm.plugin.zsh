command -v npm >/dev/null 2>&1 || return

## Update npm global path
export PATH="$HOME/.npm-global/bin:$PATH"

## Source OMZ npm plugin
source "$ZSH/plugins/npm/npm.plugin.zsh"
