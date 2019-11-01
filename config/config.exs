# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :pjeski,
  ecto_repos: [Pjeski.Repo]

# Configures the endpoint
config :pjeski, PjeskiWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Kkpy/olWADIHhc0fK7C/K2YuBOE3u2BTzJZAnqeI59WAH33cl57Snvee6xGETJfm",
  render_errors: [view: PjeskiWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Pjeski.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Pow (authentication)
config :pjeski, :pow,
  user: Pjeski.Users.User,
  repo: Pjeski.Repo,
  web_module: PjeskiWeb

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
