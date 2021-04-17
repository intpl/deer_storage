#!/bin/sh
while :; do sleep 6h; echo "reloading nginx..."; nginx -s reload; done &
