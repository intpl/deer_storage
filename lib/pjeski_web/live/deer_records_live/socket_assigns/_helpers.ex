defmodule PjeskiWeb.DeerRecordsLive.Index.SocketAssigns.Helpers do
  import PjeskiWeb.LiveHelpers, only: [keys_to_atoms: 1]
  import Pjeski.DeerRecords, only: [get_record!: 3]

  def atomize_and_merge_table_id_to_attrs(attrs, table_id), do: Map.merge(attrs, %{"deer_table_id" => table_id}) |> keys_to_atoms

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
