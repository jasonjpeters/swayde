command -v hellwal >/dev/null 2>&1 || return

if [ -f "$HOME/.cache/hellwal/variables.sh" ]; then
    source "$HOME/.cache/hellwal/variables.sh"
fi

if [ -f "$HOME/.cache/hellwal/terminal.sh" ]; then
    source "$HOME/.cache/hellwal/terminal.sh"
fi
