defmodule DeerStorage.MixProject do
  use Mix.Project

  def project do
    [
      app: :deer_storage,
      version: "0.1.0",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {DeerStorage.Application, []},
      extra_applications: [
        :mnesia,
        :logger,
        :runtime_tools,
        :timex,
        :phoenix_ecto,
        :bamboo,
        :os_mon,
        :plug
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      # Default
      {:phoenix, "~> 1.6", override: true},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_ecto, "~> 4.7"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.5.1"},

      # Non-default
      {:pow, "~> 1.0.39"},
      {:bamboo, "~> 2.2"},
      {:timex, "~> 3.5"},
      {:tzdata, "~> 1.1.0"},
      {:phoenix_live_view, "~> 0.18.0"},
      {:floki, ">= 0.0.0", only: :test},
      {:faker, "~> 0.13", only: [:test, :dev]},
      {:phoenix_live_dashboard, "~> 0.7"},
      {:telemetry_poller, "~> 1.0"},
      {:telemetry_metrics, "~> 0.6"},
      {:poison, "~> 5.0"},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:csv, "~> 2.4"},
      {:ecto_psql_extras, "~> 0.8"},
      {:xxhash, "~> 0.3.1"},
      {:navigation_history, "~> 0.3"},
      {:circular_buffer, "~> 0.3"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      seeds: ["run priv/repo/seeds.exs"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
