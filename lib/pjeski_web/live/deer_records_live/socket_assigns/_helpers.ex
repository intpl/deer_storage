defmodule PjeskiWeb.DeerRecordsLive.Index.SocketAssigns.Helpers do
  import PjeskiWeb.LiveHelpers, only: [keys_to_atoms: 1]
  import Pjeski.DeerRecords, only: [get_record!: 3]
  alias Pjeski.DeerRecords.DeerField

  def atomize_and_merge_table_id_to_attrs(attrs, table_id), do: Map.merge(attrs, %{"deer_table_id" => table_id}) |> keys_to_atoms

  def append_missing_fields_to_record(record, table_id, subscription) do
    table = Enum.find(subscription.deer_tables, fn dt -> dt.id == table_id end)

    table_columns_ids = Enum.map(table.deer_columns, fn dc -> dc.id  end)
    fields_ids = Enum.map(record.deer_fields, fn df -> df.deer_column_id end)
    missing_fields = (table_columns_ids -- fields_ids) |> Enum.map(fn id -> %DeerField{deer_column_id: id, content: nil} end)

    Map.merge(record, %{deer_fields: record.deer_fields ++ missing_fields})
  end

  def find_record_in_list_or_database(subscription, records, id, table_id) do
    id = id |> String.to_integer

    Enum.find(records, fn record -> record.id == id end) || get_record!(subscription.id, table_id, id)
  end

  def reduce_list_with_function(list, function) do
    Enum.reduce(list, [], fn item, acc_list ->
      case function.(item) do
        nil -> acc_list
        reduced_item -> acc_list ++ [reduced_item]
      end
    end)
  end

  def try_to_replace_record(records, updated_record) do
    case Enum.find_index(records, fn %{id: id} -> updated_record.id == id end) do
      nil -> nil
      idx -> List.replace_at(records, idx, updated_record)
    end
  end
end
