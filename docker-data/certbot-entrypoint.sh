#!/usr/bin/env bash

domains=($APP_HOST) # TODO
rsa_key_size=4096
data_path="/config_and_certificates"
letsencrypt_path="/etc/letsencrypt"

mkdir -p $letsencrypt_path

generate_self_signed_certificate () {
   echo "### Generating self-signed certificates in ${data_path}"
   openssl req -x509 -nodes -newkey rsa:${rsa_key_size} -days 24855\
      -keyout "${data_path}/privkey.pem" \
      -out "${data_path}/fullchain.pem" \
      -subj "/CN=${domains}"
   return 0
}

if [ ! -e "$letsencrypt_path/conf/options-ssl-nginx.conf" ] || [ ! -e "$data_path/ssl-dhparams.pem" ]; then
  echo " Downloading recommended TLS parameters ..."
  mkdir -p "$letsencrypt_path/conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$letsencrypt_path/conf/options-ssl-nginx.conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$data_path/ssl-dhparams.pem"
  echo
fi

if [ $LETSENCRYPT_ENABLED == 1 ]; then
   echo "### LetsEncrypt is enabled for domain ${APP_HOST}"
   path="$letsencrypt_path/live/$domains"
   mkdir -p $path

   if [ ! -e "$data_path/privkey.pem" ] || [ ! -e "$data_path/fullchain.pem" ]; then
      generate_self_signed_certificate
      echo "### Generated self-signed certificate. Will request LetsEncrypt certificates during next run..."
   else
      echo "### Certificate found. Verifying..."

      if [ "$(openssl x509 -in ${data_path}/fullchain.pem -text | grep -c "Let's Encrypt")" -ge 1 ]; then
         echo "### Found Let's Encrypt certificate. Looping renewal every 12 hours..."

         while true; do
           certbot renew
           echo "### Copying certificates and waiting 12h for next renewal attempt..."
           cp $path/privkey.pem $data_path/privkey.pem
           cp $path/fullchain.pem $data_path/fullchain.pem
           sleep 12h
         done
      else
         echo "### Found self-signed certificate. Requesting Let's Encrypt certificate for $domains"

         #Join $domains to -d args
         domain_args=""
         for domain in "${domains[@]}"; do
            domain_args="$domain_args -d $domain"
         done

         # Select appropriate email arg
         case "$LETSENCRYPT_EMAIL" in
            "") email_arg="--register-unsafely-without-email" ;;
            *) email_arg="--email $LETSENCRYPT_EMAIL" ;;
         esac

         # Enable staging mode if needed
         if [ $LETSENCRYPT_STAGING != "0" ]; then
           echo "### Setting Let's Encrypt to staging mode..."
           staging_arg="--staging";
         else
            staging_arg="";
         fi

         certbot certonly --webroot -w /var/www/certbot \
            $staging_arg \
            $email_arg \
            $domain_args \
            --rsa-key-size $rsa_key_size \
            --agree-tos \
            --non-interactive \
            --force-renewal

         if [ $? -eq 0 ]; then
            cp $path/privkey.pem $data_path/privkey.pem
            cp $path/fullchain.pem $data_path/fullchain.pem

            echo "### Copied LetsEncrypt certificate. Nginx will restart with a new certificate..."

            exit 0
         else
            echo "### Please inspect the problem with generating LetsEncrypt certificate..."
            echo "### Sleeping 5 seconds before restart..."
            sleep 5

            exit 1
         fi
      fi
   fi
else
   if [ ! -e "$data_path/fullchain.pem" ] || [ ! -e "$data_path/privkey.pem" ]; then
      generate_self_signed_certificate
   else
      echo "### Found self signed certificate. Skipping..."
   fi

   echo "### Sleeping forever..."

   sleep infinity
fi
