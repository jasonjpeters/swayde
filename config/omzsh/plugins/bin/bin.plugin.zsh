update_path() {
    # Remove any previous bin path from PATH
    PATH=$(echo "$PATH" | awk -v RS=: -v ORS=: '$0 != "'"$OLDPWD/bin"'" {print}' | sed 's/:$//')

    # Add bin directory if it exists
    if [[ -d "$PWD/bin" ]]; then
        export PATH="$PWD/bin:$PATH"
    fi
}

chpwd_functions+=(update_path)

update_path
