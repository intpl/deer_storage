defmodule DeerCache.SubscriptionStorageCache do
  use GenServer
  alias Phoenix.PubSub

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, [{:ets_table_name, :deer_files_disk_usage_by_subscription_id}], opts)

  def fetch_data(subscription_id) do
    case GenServer.call(__MODULE__, {:get, subscription_id}) do
      [] -> {0, 0}
      [{_subscription_id, data}] -> data
    end
  end

  def handle_call({:get, subscription_id}, _from, state) do
    {:reply, get(subscription_id, state), state}
  end

  def handle_cast({:uploaded_file, subscription_id, file_size_in_kilobytes}, state) do
    new_data = case get(subscription_id, state) do
                  [] -> {1, file_size_in_kilobytes}
                  [{^subscription_id, {files, kilobytes}}] -> {files + 1, kilobytes + file_size_in_kilobytes}
                end

    set(subscription_id, new_data, state)

    PubSub.broadcast Pjeski.PubSub, "subscription_deer_storage:#{subscription_id}", {:cached_deer_storage_changed, new_data}

    {:noreply, state}
  end

  def handle_cast({:removed_files, subscription_id, count, file_size_in_kilobytes}, state) do
    [{^subscription_id, {files, kilobytes}}] = get(subscription_id, state)
    new_data = {files - count, kilobytes - file_size_in_kilobytes}

    set(subscription_id, new_data, state)

    PubSub.broadcast Pjeski.PubSub, "subscription_deer_storage:#{subscription_id}", {:cached_deer_storage_changed, new_data}

    {:noreply, state}
  end

  def init(args) do
    [{:ets_table_name, ets_table_name}] = args
    :ets.new(ets_table_name, [:named_table, :set, :private])
    grouped_data = Pjeski.Services.CalculateDeerStorage.run!()
    state = %{ets_table_name: ets_table_name}

    for {subscription_id, {files, kilobytes}} <- grouped_data, do: set(subscription_id, {files, kilobytes}, state)

    {:ok, state}
  end

  defp set(subscription_id, data, %{ets_table_name: ets_table_name}) do
    true = :ets.insert(ets_table_name, {subscription_id, data})
  end

  defp get(subscription_id, %{ets_table_name: ets_table_name}) do
    :ets.lookup(ets_table_name, subscription_id)
  end
end
