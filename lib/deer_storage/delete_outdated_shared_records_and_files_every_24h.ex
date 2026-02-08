defmodule DeerStorage.DeleteOutdatedSharedRecordsAndFilesEvery24h do
  require Logger
  use GenServer

  def start_link(_opts \\ []) do
    Logger.info("Starting DeleteOutdatedSharedRecordsAndFilesEvery24h worker...")
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    send(self(), :work)
    {:ok, state}
  end

  def handle_info(:work, state) do
    {records_count, _} = DeerStorage.SharedRecords.delete_outdated!()
    {files_count, _} = DeerStorage.SharedFiles.delete_outdated!()

    Logger.info(
      "Deleted #{records_count} outdated shared records and #{files_count} outdated shared files"
    )

    schedule_next_work()

    {:noreply, state}
  end

  defp schedule_next_work() do
    # 1 day in milliseconds
    Process.send_after(self(), :work, 86_400_000)
  end
end
