# DeerStorage
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
4. Run `docker-compose up`. This command will fetch all necessary docker images and compile entire application, so it will take a while. Then it will host it under your APP_HOST:APP_PORT you selected in previous steps

Above instruction works on fresh VPS installation with DNS assigned domain (with Let's Encrypt) as well as localhost (with self-certificate)

# What is DeerStorage?
- Collaborative and safe cloud system for files/data storage and sharing
- Containerized application to be hosted and used independently as instances
- Very fast database and files lookup, live changes without page reload using WebSockets
- Ability to "connect" records to each other, making it a sort of user level relational database
- Ready to be multi language. (I need people willing to provide translated files though)
- Ready to handle high traffic. Works well even when being hosted with limited resources (e.g. 5$/mo VPS)
# Why?
- Very easy set-up with Let's Encrypt certificate installed automatically (if enabled)
- Independent from cloud storage providers (e.g. Google, Dropbox, Microsoft). Hosted on your machine or VPS
- File previews (images are shown in gallery, video files have players, PDFs and open documents have readers in popup)
- You can share files or entire collections with just one click that generates link
- You can share collections (records) to be edited and uploaded files into
- You can have e-mail support when providing API credentials from MailGun (more services to come).
- Although untested, I am pretty sure it can be hosted under HAProxy (ports are variables in .env file)
- Ability to import `.csv` files and use them as DeerStorage tables.

# License

GNU GENERAL PUBLIC LICENSE Version 3
