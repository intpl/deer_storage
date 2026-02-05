defmodule DeerCache.RecordsCountsCache do
  use GenServer
  alias Phoenix.PubSub

  import DeerStorage.DeerRecords, only: [count_records_grouped_by_deer_table_id: 0]

  def start_link(opts \\ []),
    do:
      GenServer.start_link(__MODULE__, [{:ets_table_name, :deer_records_by_table_id_cache}], opts)

  def fetch_count(table_id) do
    case GenServer.call(__MODULE__, {:get, table_id}) do
      [] -> 0
      [{_table_id, count}] -> count
    end
  end

  def handle_call({:get, deer_table_id}, _from, state) do
    {:reply, get(deer_table_id, state), state}
  end

  def handle_call({:deleted_table, deer_table_id}, _from, state),
    do: {:reply, delete(deer_table_id, state), state}

  def handle_cast({:increment, deer_table_id, by_count}, state) do
    new_count =
      case get(deer_table_id, state) do
        [] -> by_count
        [{^deer_table_id, n}] -> n + by_count
      end

    set(deer_table_id, new_count, state)

    PubSub.broadcast(
      DeerStorage.PubSub,
      "records_counts:#{deer_table_id}",
      {:cached_records_count_changed, deer_table_id, new_count}
    )

    {:noreply, state}
  end

  def handle_cast({:decrement, deer_table_id, by_count}, state) do
    [{^deer_table_id, count}] = get(deer_table_id, state)
    new_count = count - by_count

    set(deer_table_id, new_count, state)

    PubSub.broadcast(
      DeerStorage.PubSub,
      "records_counts:#{deer_table_id}",
      {:cached_records_count_changed, deer_table_id, new_count}
    )

    {:noreply, state}
  end

  def init(args) do
    [{:ets_table_name, ets_table_name}] = args
    :ets.new(ets_table_name, [:named_table, :set, :private])
    grouped_counts = count_records_grouped_by_deer_table_id()
    state = %{ets_table_name: ets_table_name}

    for %{deer_table_id: id, count: count} <- grouped_counts, do: set(id, count, state)

    {:ok, state}
  end

  defp set(table_id, count, %{ets_table_name: ets_table_name}) do
    true = :ets.insert(ets_table_name, {table_id, count})
  end

  defp get(table_id, %{ets_table_name: ets_table_name}) do
    :ets.lookup(ets_table_name, table_id)
  end

  defp delete(table_id, %{ets_table_name: ets_table_name}) do
    :ets.delete(ets_table_name, table_id)
  end
end
