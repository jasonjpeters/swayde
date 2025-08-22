#!/usr/bin/env bash

task::run() {
    local fpks=(
        app.zen_browser.zen
        io.httpie.Httpie
        com.github.IsmaelMartinez.teams_for_linux
        com.slack.Slack
        io.dbeaver.DBeaverCommunity
        io.dbeaver.DBeaverCommunity.Client.pgsql
        io.dbeaver.DBeaverCommunity.Client.mariadb
    )

    for fpk in "${fpks[@]}"; do
        fpk_install "${fpk}" --scope=system
    done
}
