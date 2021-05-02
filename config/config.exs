# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config
# TODO: use Config module: https://hexdocs.pm/elixir/Config.html

config :deer_storage,
  ecto_repos: [DeerStorage.Repo]

config :deer_storage, DeerStorage.Gettext, default_locale: "en", locales: ~w(en pl)

# Configures the endpoint
config :deer_storage, DeerStorageWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Kkpy/olWADIHhc0fK7C/K2YuBOE3u2BTzJZAnqeI59WAH33cl57Snvee6xGETJfm",
  render_errors: [view: DeerStorageWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: DeerStorage.PubSub,
  live_view: [
    signing_salt: "Cx4+NQzV+jnvqWiZKk+v0u1YPxyS/vIg", # overwrite in production
    hibernate_after: 3_600_000 # 1 hour
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Pow (authentication)
config :deer_storage, :pow,
  user: DeerStorage.Users.User,
  repo: DeerStorage.Repo,
  mailer_backend: DeerStorageWeb.PowMailer,
  web_module: DeerStorageWeb,
  web_mailer_module: DeerStorageWeb,
  cache_store_backend: Pow.Store.Backend.MnesiaCache,
  extensions: [PowResetPassword, PowEmailConfirmation, PowPersistentSession, PowInvitation]
  # controller_callbacks: Pow.Extension.Phoenix.ControllerCallbacks

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
