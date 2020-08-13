defmodule PjeskiWeb.LiveHelpers do
  alias Pjeski.DeerRecords.DeerField

  def cached_counts(deer_tables) do
    Enum.reduce(deer_tables, %{}, fn %{id: id}, acc ->
      Map.merge(acc, %{id => DeerCache.RecordsCountsCache.fetch_count(id)})
    end)
  end

  def toggle_record_in_list([], record), do: [record]
  def toggle_record_in_list(list, record) do
    case Enum.find_index(list, fn %{id: id} -> record.id == id end) do
      nil -> [record | list]
      idx ->  List.delete_at(list, idx)
    end
  end

  def maybe_update_record_in_list(list, record) do
    case Enum.find_index(list, fn %{id: id} -> record.id == id end) do
      nil -> list
      idx -> List.replace_at(list, idx, record)
    end
  end

  def maybe_delete_record_in_list(list, record_id) do
    case Enum.find_index(list, fn %{id: id} -> record_id == id end) do
      nil -> list
      idx -> List.delete_at(list, idx)
    end
  end

  def is_expired?(%{expires_on: date}), do: Date.diff(date, Date.utc_today) < 1

  def keys_to_atoms(%{} = map) do
    Enum.reduce(map, %{}, fn
    # String.to_existing_atom saves us from overloading the VM by
    # creating too many atoms. It'll always succeed because all the fields
    # in the database already exist as atoms at runtime.
    {key, value}, acc when is_atom(key) -> Map.put(acc, key, value)
      {key, value}, acc when is_binary(key) -> Map.put(acc, String.to_existing_atom(key), value)
    end)
  end

  def append_missing_fields_to_record(record, table_id, subscription) do
    table = Enum.find(subscription.deer_tables, fn dt -> dt.id == table_id end)

    table_columns_ids = Enum.map(table.deer_columns, fn dc -> dc.id end)
    fields_ids = Enum.map(record.deer_fields, fn df -> df.deer_column_id end)
    missing_fields = (table_columns_ids -- fields_ids) |> Enum.map(fn id -> %DeerField{deer_column_id: id, content: nil} end)

    Map.merge(record, %{deer_fields: record.deer_fields ++ missing_fields})
  end
end
