#!/usr/bin/env bash
set -euo pipefail

data_path="/config_and_certificates"

reload_nginx () {
    echo "Reloading nginx..."
    nginx -s reload
}

loop_reloading_nginx_every_6h () {
    while [ $LETSENCRYPT_ENABLED == 1 ]; do
        echo "Will reload Nginx in 6h..."
        sleep 6h
        reload_nginx
    done
}

certificate_matching_letsencrypt () {
    openssl x509 -in ${data_path}/fullchain.pem -text | grep -c "Let's Encrypt"
}

if [ $LETSENCRYPT_ENABLED == 1 ]; then
    echo "### Looping nginx-proxy reloading script..."

    while [ "$(certificate_matching_letsencrypt)" -eq 0 ]; do
        echo "Waiting for Let's Encrypt certificate..."
        sleep 1;
    done;

    # TODO what if it's expired? loop: wait a couple of seconds and check again
    reload_nginx
    loop_reloading_nginx_every_6h
fi &
