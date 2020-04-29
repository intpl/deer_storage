defmodule Pjeski.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {Phoenix.PubSub, [name: Pjeski.PubSub, adapter: Phoenix.PubSub.PG2]},
      Pjeski.Repo,
      PjeskiWeb.Telemetry,
      PjeskiWeb.Endpoint,
      Pow.Store.Backend.MnesiaCache,
      # # Or in a distributed system:
      # {Pow.Store.Backend.MnesiaCache, extra_db_nodes: Node.list()},
      # Pow.Store.Backend.MnesiaCache.Unsplit # Recover from netsplit
      Pjeski.Scheduler
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Pjeski.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PjeskiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
