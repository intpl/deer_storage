defmodule PjeskiWeb.LiveHelpers do
  def list_new_table_ids(old_deer_tables, new_deer_tables) do
    old_ids = Enum.map(old_deer_tables, fn dt -> dt.id end)
    new_ids = Enum.map(new_deer_tables, fn dt -> dt.id end)

    new_ids -- old_ids
  end

  def cached_counts(deer_tables) do
    Enum.reduce(deer_tables, %{}, fn %{id: id}, acc ->
      Map.merge(acc, %{id => DeerCache.RecordsCountsCache.fetch_count(id)})
    end)
  end

  def is_expired?(%{expires_on: date}), do: Date.diff(date, Date.utc_today) < 1

  def keys_to_atoms(%{} = map) do
    Enum.reduce(map, %{}, fn
    {key, value}, acc when is_atom(key) -> Map.put(acc, key, value)
    {key, value}, acc when is_binary(key) -> Map.put(acc, String.to_existing_atom(key), value)
    end)
  end
end
