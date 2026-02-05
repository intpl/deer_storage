defmodule DeerStorageWeb.DeerRecordsLive.Index.SocketAssigns.Helpers do
  import Ecto.Changeset, only: [change: 1, put_embed: 3, apply_changes: 1, fetch_field!: 2]

  import Phoenix.Component, only: [assign: 3]
  import DeerStorageWeb.LiveHelpers, only: [keys_to_atoms: 1]
  import DeerStorage.DeerRecords, only: [get_record!: 3]
  import DeerStorageWeb.DeerRecordView, only: [mimetype_is_previewable?: 1]

  alias DeerStorage.DeerRecords.DeerField
  alias DeerStorage.DeerRecords.DeerFile

  def any_entry_started_upload?([]), do: false

  def any_entry_started_upload?(entries),
    do: Enum.any?(entries, fn entry -> entry.progress > 0 end)

  def connected_records_or_deer_files_changed?(changeset, %{
        deer_files: deer_files,
        connected_deer_records_ids: connected_deer_records_ids
      }) do
    fetch_field!(changeset, :connected_deer_records_ids) != connected_deer_records_ids ||
      fetch_field!(changeset, :deer_files) != deer_files
  end

  def atomize_and_merge_table_id_to_attrs(attrs, table_id),
    do: Map.merge(attrs, %{"deer_table_id" => table_id}) |> keys_to_atoms

  def assign_next_previewable(socket, deer_files, current_deer_file_id) do
    next_deer_file =
      Enum.reduce_while(deer_files, :finding_current, fn
        df, :finding_current ->
          if df.id == current_deer_file_id,
            do: {:cont, :found_current},
            else: {:cont, :finding_current}

        df, :found_current ->
          if mimetype_is_previewable?(df.mimetype), do: {:halt, df}, else: {:cont, :found_current}
      end)

    assign_preview_deer_file_or_untouched_socket(socket, next_deer_file)
  end

  def assign_previous_previewable(socket, deer_files, current_deer_file_id) do
    previous_deer_file =
      case Enum.find_index(deer_files, fn df -> df.id == current_deer_file_id end) do
        0 ->
          nil

        n ->
          deer_files
          |> Enum.slice(0, n)
          |> Enum.reverse()
          |> Enum.find(fn %{mimetype: mimetype} -> mimetype_is_previewable?(mimetype) end)
      end

    assign_preview_deer_file_or_untouched_socket(socket, previous_deer_file)
  end

  def overwrite_deer_fields(record, deer_fields) do
    change(record)
    |> put_embed(:deer_fields, [])
    |> apply_changes
    |> change()
    |> put_embed(:deer_fields, deer_fields)
  end

  def append_missing_fields_to_record(record, table_id, subscription) do
    table = Enum.find(subscription.deer_tables, fn dt -> dt.id == table_id end)

    table_columns_ids = Enum.map(table.deer_columns, fn dc -> dc.id end)
    fields_ids = Enum.map(record.deer_fields, fn df -> df.deer_column_id end)

    missing_fields =
      (table_columns_ids -- fields_ids)
      |> Enum.map(fn id -> %DeerField{deer_column_id: id, content: nil} end)

    Map.merge(record, %{deer_fields: record.deer_fields ++ missing_fields})
  end

  def find_record_in_opened_records(opened_records, record_id) do
    Enum.find(opened_records, fn [record, _connected_records] -> record.id == record_id end)
  end

  def find_record_in_list_or_database(subscription, records, id, table_id) do
    id = id |> String.to_integer()

    Enum.find(records, fn record -> record.id == id end) ||
      get_record!(subscription.id, table_id, id)
  end

  def reduce_list_with_function(list, function) do
    Enum.reduce(list, [], fn item, acc_list ->
      case function.(item) do
        nil -> acc_list
        reduced_item -> acc_list ++ [reduced_item]
      end
    end)
  end

  def try_to_update_record(records, updated_record) do
    case Enum.find_index(records, fn %{id: id} -> updated_record.id == id end) do
      nil -> nil
      idx -> [updated_record | List.delete_at(records, idx)]
    end
  end

  def find_record_in_opened_or_connected_records([], _record_id),
    do: raise("no opened records found")

  def find_record_in_opened_or_connected_records([[%{id: id} = record, _] | _], id), do: record

  def find_record_in_opened_or_connected_records([[_, connected_records] | rest], record_id) do
    Enum.find(connected_records, fn record -> record.id == record_id end) ||
      find_record_in_opened_or_connected_records(rest, record_id)
  end

  defp assign_preview_deer_file_or_untouched_socket(socket, %DeerFile{} = df),
    do: assign(socket, :preview_deer_file, df)

  defp assign_preview_deer_file_or_untouched_socket(socket, _), do: socket
end
