#!/usr/bin/env bash
set -euo pipefail

trap exit TERM;
while :;
do certbot renew;
   sleep 12h & wait ${!};
done;
