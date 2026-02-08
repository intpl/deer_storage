defmodule DeerCache.Supervisor do
  use Supervisor

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      {DeerCache.RecordsCountsCache, name: DeerCache.RecordsCountsCache},
      {DeerCache.SubscriptionStorageCache, name: DeerCache.SubscriptionStorageCache},
      DeerStorage.DeleteOutdatedSharedRecordsAndFilesEvery24h
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
