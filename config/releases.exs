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
