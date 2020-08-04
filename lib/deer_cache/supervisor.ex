defmodule DeerCache.Supervisor do
  use Supervisor

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      worker(DeerCache.RecordsCountsCache, [[name: DeerCache.RecordsCountsCache]])
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
