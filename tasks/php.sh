#!/usr/bin/env bash
# shellcheck disable=SC2312

task::run() {
    local pkgs=(
        composer
        php
        php-cli
        php-common
        php-opcache
        php-devel
        php-mbstring
        php-xml
        php-intl
        php-gd
        php-curl
        php-bcmath
        php-json
        php-zip
        php-tokenizer
        php-dom
        php-fileinfo
        php-pdo
        php-mysqlnd
        php-pgsql
        php-sqlite3
        php-exif
        php-soap
        php-sodium
        php-gettext
        php-sockets
        php-pecl-redis
        php-pecl-apcu
        php-pecl-imagick
    )

    dnf_install "${pkgs[@]}"

    # Globally allow ALL Composer plugins (safe for headless installs)
    composer global config allow-plugins true

    # Global Composer tools (latest versions, no constraints)
    composer global require --no-interaction --quiet \
        laravel/installer \
        phpunit/phpunit \
        phpstan/phpstan \
        pestphp/pest \
        friendsofphp/php-cs-fixer \
        cakephp/cakephp-codesniffer \
        wp-cli/wp-cli-bundle \
        wp-coding-standards/wpcs \
        dealerdirect/phpcodesniffer-composer-installer \
        phpstan/extension-installer \
        php-stubs/wordpress-stubs
}
