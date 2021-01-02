defmodule PjeskiWeb.DeerRecordsLive.Index.SocketAssigns.UploadingFiles do
  import Phoenix.LiveView, only: [assign: 3]
  import PjeskiWeb.DeerRecordView, only: [deer_table_from_subscription: 2]

  def assign_closed_file_upload_modal(socket), do: assign(socket, :uploading_file_for_record_id, nil)

  def assign_opened_file_upload_modal(%{assigns: %{opened_records: opened_records, current_subscription: subscription}} = socket, table_id, record_id) do
    deer_table_from_subscription(subscription, table_id) || raise "invalid table id"

    record_id = String.to_integer(record_id)
    uploading_record = find_record_in_opened_or_connected_records(opened_records, record_id)

    assign(socket, :uploading_file_for_record_id, uploading_record.id)
  end

  defp find_record_in_opened_or_connected_records([], _record_id), do: raise "invalid record id"
  defp find_record_in_opened_or_connected_records([[%{id: id} = record, _] | _], id), do: record
  defp find_record_in_opened_or_connected_records([[_, connected_records] | rest], record_id) do
    find_record_in_list(connected_records, record_id) || find_record_in_opened_or_connected_records(rest, record_id)
  end

  defp find_record_in_list(records, id), do: Enum.find(records, fn record -> record.id == id end)
end
