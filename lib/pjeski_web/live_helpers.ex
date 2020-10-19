defmodule PjeskiWeb.LiveHelpers do
  alias Pjeski.DeerRecords.DeerField

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

  def maybe_delete_records_from_list_by_ids(list, ids) do
    Enum.reject(list, fn %{id: id} -> Enum.member?(ids, id) end)
  end

  def maybe_delete_record_from_list_by_id(list, record_id) do
    case Enum.find_index(list, fn %{id: id} -> record_id == id end) do
      nil -> list
      idx -> List.delete_at(list, idx)
    end
  end

  def update_current_record_with_connected_records(list, id, connected_records) do
    case Enum.find_index(list, fn [%{id: record_id}, _old_connected_record] -> id == record_id end) do
      nil -> list # this is neccessary due to race condition
      idx ->
        [record, _old_connected_records] = Enum.at(list, idx)
        List.replace_at(list, idx, [record, connected_records])
    end
  end

  def toggle_current_record_in_list([], current_record), do: [current_record]
  def toggle_current_record_in_list(list, [%{id: record_id}, _] = current_record) do
    case Enum.find_index(list, fn [%{id: id}, _connected_records] -> record_id == id end) do
      nil -> [current_record | list]
      idx ->  List.delete_at(list, idx)
    end
  end

  def maybe_update_current_record_in_list(list, [record, connected_records] = current_record) do
    case Enum.find_index(list, fn [%{id: id}, _connected_records] -> record.id == id end) do
      nil -> list
      idx -> List.replace_at(list, idx, current_record)
    end
  end

  def maybe_delete_current_record_from_list(list, record_id) do
    case Enum.find_index(list, fn [%{id: id}, _] -> record_id == id end) do
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
