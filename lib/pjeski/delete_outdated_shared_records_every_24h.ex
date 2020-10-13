defmodule Pjeski.DeleteOutdatedSharedRecordsEvery24h do
  require Logger
  use GenServer

  def start_link do
    Logger.info("Starting DeleteOutdatedSharedRecordsEvery24h worker...")
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    send(self(), :work)
    {:ok, state}
  end

  def handle_info(:work, state) do
    {count, _} = Pjeski.SharedRecords.delete_outdated!
    Logger.info("Deleted #{count} outdated shared records")

    schedule_next_work()

    {:noreply, state}
  end

  defp schedule_next_work() do
    Process.send_after(self(), :work, 86_400_000) # 1 day in milliseconds
  end
end
