use Mix.Config

# Configure your database
config :pjeski, Pjeski.Repo,
  username: "pjeski",
  password: "pjeski",
  database: "pjeski_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :pjeski, PjeskiWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :pjeski, PjeskiWeb.PowMailer, adapter: Bamboo.TestAdapter
