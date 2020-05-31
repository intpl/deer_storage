defmodule Pjeski.MixProject do
  use Mix.Project

  def project do
    [
      app: :pjeski,
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
      mod: {Pjeski.Application, []},
      extra_applications: [:logger, :runtime_tools, :timex, :phoenix_ecto, :bamboo, :os_mon]
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
      {:phoenix, "~> 1.5", override: true},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_ecto, github: "phoenixframework/phoenix_ecto"}, # FIXME, but only after release greater than 4.1.0
      {:ecto_sql, "~> 3.4"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.14.2"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},

      # Non-default
      {:pow, "~> 1.0.20"},
      {:bamboo, "~> 1.4"},
      {:phoenix_active_link, "~> 0.3.0"},
      {:timex, "~> 3.5"},
      {:tzdata, "~> 1.0.1"},
      {:quantum, "~> 2.3"},
      {:phoenix_live_view, "~> 0.12.1"},
      {:floki, ">= 0.0.0", only: :test},
      {:faker, "~> 0.13", only: [:test, :dev]},
      {:phoenix_live_dashboard, "~> 0.1"},
      {:telemetry_poller, "~> 0.4"},
      {:telemetry_metrics, "~> 0.4"},
      {:poison, "~> 4.0"}
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
