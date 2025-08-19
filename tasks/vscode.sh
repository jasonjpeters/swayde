#!/use/bin/env bash

task::run() {
    repo_ensure \
        --id code \
        --name "Visual Studio Code" \
        --baseurl https://packages.microsoft.com/yumrepos/vscode \
        --gpgkey-url https://packages.microsoft.com/keys/microsoft.asc \
        --gpgkey-match "Microsoft (Release signing)"
    dnf_install code
}
