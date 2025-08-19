#!/bin/bash

# Define once, even if sourced multiple times
if ! declare -F webapp_install >/dev/null 2>&1; then
    webapp_install() {
        local app_name app_url icon_url

        # --- args / prompts (gum fallback to read) ---
        if [[ $# -ne 3 ]]; then
            echo "Create a webapp:"
            if command -v gum >/dev/null 2>&1; then
                app_name="$(gum input --prompt 'Name> ' --placeholder 'WebApp Name')"
                app_url="$(gum input --prompt 'URL> ' --placeholder 'https://example.com')"
                icon_url="$(gum input --prompt 'Icon URL> ' --placeholder 'See https://dashboardicons.com (must use PNG!)')"
            else
                printf 'Name> '
                IFS= read -r app_name
                printf 'URL> '
                IFS= read -r app_url
                printf 'Icon URL> '
                IFS= read -r icon_url
            fi
        else
            app_name="$1"
            app_url="$2"
            icon_url="$3"
        fi

        if [[ -z "$app_name" || -z "$app_url" || -z "$icon_url" ]]; then
            printf 'App name, URL, and icon are required!\n' >&2
            return 1
        fi

        # --- safe ID (for filenames/WMClass) ---
        local app_id
        app_id="$(printf '%s' "$app_name" |
            tr '[:upper:]' '[:lower:]' |
            sed -E 's/[[:space:]]+/-/g; s/[^a-z0-9._-]+/-/g; s/^-+|-+$//g')"

        # --- paths ---
        local xdg_app_dir icon_dir desktop_file icon_path
        xdg_app_dir="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
        icon_dir="$xdg_app_dir/icons"
        desktop_file="$xdg_app_dir/${app_id}.desktop"
        icon_path="$icon_dir/${app_id}.png"

        mkdir -p "$icon_dir"
        rm -f -- "$desktop_file" "$icon_path"

        # --- fetch icon (curl or wget) ---
        if command -v curl >/dev/null 2>&1; then
            curl -fsSL -o "$icon_path" "$icon_url" || {
                echo "Error: Failed to download icon." >&2
                return 1
            }
        elif command -v wget >/dev/null 2>&1; then
            wget -qO "$icon_path" "$icon_url" || {
                echo "Error: Failed to download icon." >&2
                return 1
            }
        else
            echo "Error: need curl or wget to download icon." >&2
            return 1
        fi

        # --- browser (env override or auto-detect) ---
        local browser="${WEBAPP_BROWSER:-}"
        if [[ -n "$browser" ]] && ! command -v "$browser" >/dev/null 2>&1; then
            printf 'warn: WEBAPP_BROWSER=%s not found; auto-selecting.\n' "$browser" >&2
            browser=""
        fi
        if [[ -z "$browser" ]]; then
            for b in chromium-browser chromium google-chrome-stable google-chrome brave vivaldi; do
                command -v "$b" >/dev/null 2>&1 && {
                    browser="$b"
                    break
                }
            done
        fi
        if [[ -z "$browser" ]]; then
            echo "Error: no Chromium-based browser found in PATH." >&2
            return 1
        fi

        # --- write .desktop ---
        cat >"$desktop_file" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$app_name
Comment=$app_name
Exec=$browser --new-window --ozone-platform=wayland --app="$app_url" --name="$app_id" --class="$app_id"
StartupWMClass=$app_id
Icon=$icon_path
Terminal=false
StartupNotify=true
Categories=Network;WebBrowser;
EOF

        chmod 0644 "$desktop_file"

        # Optional cache refresh (safe no-op if missing)
        command -v update-desktop-database >/dev/null 2>&1 &&
            update-desktop-database "$xdg_app_dir" >/dev/null 2>&1 || true

        printf 'Created %s\n' "$desktop_file"
        return 0
    }
fi
