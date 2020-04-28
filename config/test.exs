use Mix.Config

# Configure your database
config :pjeski, Pjeski.Repo,
  username: "pjeski",
  password: "pjeski",
  database: "pjeski_test",
  hostname: "localhost",
  secret_key_base: String.duplicate("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", 2),
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :pjeski, PjeskiWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :pjeski, PjeskiWeb.PowMailer, adapter: Bamboo.TestAdapter

config :pjeski, :pow, cache_store_backend: PjeskiWeb.EtsCacheMock,
  message_verifier: Pjeski.Test.Pow.MessageVerifier,
  cache_store_backend: Pow.Store.Backend.EtsCacheMock
