import Config

# Configure your database
config :deer_storage, DeerStorage.Repo,
  username: "pjeski",
  password: "pjeski",
  database: "deer_storage_test",
  hostname: "localhost",
  secret_key_base: String.duplicate("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", 2),
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :deer_storage, DeerStorageWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

config :deer_storage, DeerStorageWeb.PowMailer, adapter: Bamboo.TestAdapter

config :deer_storage, :pow,
  cache_store_backend: DeerStorageWeb.EtsCacheMock,
  message_verifier: DeerStorage.Test.Pow.MessageVerifier,
  cache_store_backend: Pow.Store.Backend.EtsCacheMock
