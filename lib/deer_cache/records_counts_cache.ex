defmodule DeerCache.RecordsCountsCache do
  use GenServer
  alias Phoenix.PubSub

  import Pjeski.DeerRecords, only: [count_records_grouped_by_deer_table_id: 0]

  # TODO
  # handle callback from subscription_changed and verify all changed tables

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, [{:ets_table_name, :deer_records_by_table_id_cache}], opts)

  def fetch_count(table_id) do
    case GenServer.call(__MODULE__, {:get, table_id}) do
      [] -> 0
      [{_table_id, count}] -> count
    end
  end

  def handle_call({:get, deer_table_id}, _from, state) do
    {:reply, get(deer_table_id, state), state}
  end

  def handle_cast({:increment, deer_table_id}, state) do
    new_count = case get(deer_table_id, state) do
                  [] ->  1
                  [{^deer_table_id, n}] -> n + 1
                end

    set(deer_table_id, new_count, state)

    PubSub.broadcast Pjeski.PubSub, "records_counts:#{deer_table_id}", {:cached_records_count_changed, deer_table_id, new_count}

    {:noreply, state}
  end

  def handle_cast({:decrement, deer_table_id}, state) do
    [{^deer_table_id, count}] = get(deer_table_id, state)
    new_count = count - 1

    set(deer_table_id, new_count, state)

    PubSub.broadcast Pjeski.PubSub, "records_counts:#{deer_table_id}", {:cached_records_count_changed, deer_table_id, new_count}

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
end
