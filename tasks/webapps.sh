#!/usr/bin/env bash

task::run() {
    webapp_install "WhatsApp" "https://web.whatsapp.com/" "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/whatsapp.png"
    webapp_install "ChatGPT" "https://chatgpt.com/" "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/chatgpt.png"
    webapp_install "YouTube" "https://youtube.com/" "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/youtube.png"
    webapp_install "GitHub" "https://github.com/" "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/github-light.png"
    webapp_install "Discord" "https://discord.com/channels/@me" "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/discord.png"
    webapp_install "Incus" "https://localhost:8443/ui" "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/incus.png"
}
