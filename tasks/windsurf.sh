#!/usr/bin/env bash

task::run() {
    repo_ensure \
        --id windsurf \
        --name "Windsurf Repository" \
        --baseurl https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/yum/repo/ \
        --gpgkey-url https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/yum/RPM-GPG-KEY-windsurf \
        --gpgkey-match "Windsurf"
    dnf_ensure windsurf
}
