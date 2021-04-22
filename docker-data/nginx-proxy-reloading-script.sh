#!/usr/bin/env bash
set -euo pipefail

data_path="/config_and_certificates"

reload_nginx () {
    echo "Reloading nginx..."
    nginx -s reload
}

loop_reloading_nginx_every_6h () {
    echo "Looping reloading every 6h..."
    while true; do
        sleep 6h
        reload_nginx
    done
}

certificate_matching_letsencrypt () {
    openssl x509 -in ${data_path}/fullchain.pem -text | grep -c "Let's Encrypt"
}

while [ $LETSENCRYPT_ENABLED == 1 ]; do
    if [ "$(certificate_matching_letsencrypt)" -ge 1 ]; then
        echo "LetsEncrypt certificate found."
        loop_reloading_nginx_every_6h
    else
        while [ certificate_matching_letsencrypt  == 0 ]; do
            echo "Waiting for LetsEncrypt certificate..."
            sleep 1;
        done

        reload_nginx
        loop_reloading_nginx_every_6h
    fi
done &
