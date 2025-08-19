#!/usr/bin/env bash

task::run() {
    if have zed; then
        log "zed already installed; skip"
        return 0
    fi

    curl -f https://zed.dev/install.sh | sh
}
