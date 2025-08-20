#!/usr/bin/env bash

task::run() {
    local fpks=(
        app.zen_browser.zen
        io.httpie.Httpie
        com.github.IsmaelMartinez.teams_for_linux
        com.slack.Slack
    )

    for fpk in "${fpks[@]}"; do
        fpk_install "${fpk}" --scope=system
    done
}
