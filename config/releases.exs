# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

config :pjeski, Pjeski.Repo,
  # ssl: true,
  username: System.fetch_env!("PGUSER"),
  password: System.fetch_env!("PGPASSWORD"),
  database: System.fetch_env!("PGDATABASE"),
  hostname: System.fetch_env!("PGHOST"),
  port: System.fetch_env!("PGPORT") |> String.to_integer,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

config :pjeski, PjeskiWeb.Endpoint,
  url: [host: {:system, "APP_HOST"}, port: 443, scheme: "https"],
  http: [port: 80],
  server: true,
  secret_key_base: System.fetch_env!("SECRET_KEY_BASE")

if System.get_env("POW_MAILGUN_API_KEY") && System.get_env("POW_MAILGUN_DOMAIN") && System.get_env("POW_MAILGUN_BASE_URI") do
  config :pjeski,
    PjeskiWeb.PowMailer,
    adapter: Bamboo.MailgunAdapter,
    base_uri: System.fetch_env!("POW_MAILGUN_BASE_URI"),
    domain: System.fetch_env!("POW_MAILGUN_DOMAIN"),
    api_key: System.fetch_env!("POW_MAILGUN_API_KEY"),
    hackney_opts: [recv_timeout: :timer.minutes(1)]
else
  # TODO: this does not work inside docker
  config :pjeski, PjeskiWeb.PowMailer, adapter: Bamboo.LocalAdapter
end
