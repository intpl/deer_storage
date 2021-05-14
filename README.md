# DeerStorage

Read more about this project here: http://gladecki.pl/2021/05/16/deerstorage/

## Installation

1. Install docker-compose
https://docs.docker.com/compose/install/
2. Clone the repository

``` sh
git clone https://github.com/intpl/deer_storage.git
cd deer_storage
```
2. Run initial script to generate `.env` file. Answer all of the questions. If you are launching it locally, just press [ENTER] until the script exits to stick with defaults (localhost, Let's Encrypt disabled, 1GB per "database" etc.)
``` sh
elixir init-setup-env.exs
```
or (if you don't have elixir installed):
``` sh
docker run -i --rm -v $(pwd)/initial-setup-env.exs:/s.exs elixir:1.11-alpine elixir /s.exs
```

3. Paste generated variables to `.env`
4. Run `docker-compose up`. This command will fetch all necessary docker images and compile entire application, so it will take a while. Then it will host it under APP_HOST:APP_PORT you selected in previous steps
5. If you selected to autopromote first registered user to administrator (which I strongly recommend), you can register and immediately log into your account (without any confirmation). 

Above instruction works on fresh VPS installation with DNS assigned domain (with Let's Encrypt) as well as localhost (with self-signed certificate)

# License

GNU GENERAL PUBLIC LICENSE Version 3
