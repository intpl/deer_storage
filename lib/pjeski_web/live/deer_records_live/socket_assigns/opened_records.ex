defmodule PjeskiWeb.DeerRecordsLive.Index.SocketAssigns.OpenedRecords do
  alias Pjeski.DeerRecords.DeerRecord
  alias Pjeski.SharedRecords

  import Phoenix.LiveView, only: [assign: 2]

  import PjeskiWeb.DeerRecordsLive.Index.SocketAssigns.Helpers, only: [reduce_list_with_function: 2, find_record_in_list_or_database: 3]
  import Pjeski.DeerRecords, only: [
    batch_delete_records: 3,
    delete_file_from_record!: 3,
    delete_record: 2,
    disconnect_records!: 3,
    get_records!: 2
  ]

  def dispatch_delete_record(%{assigns: %{opened_records: opened_records, current_subscription: subscription}} = socket, record_id) do
    [record, _connected_records] = find_record_in_opened_records(opened_records, String.to_integer(record_id))
    {:ok, _} = delete_record(subscription, record)

    socket
  end

  def dispatch_delete_file(%{assigns: %{current_subscription: %{id: subscription_id}}} = socket, record_id, file_id) do
    delete_file_from_record!(subscription_id, record_id, file_id)

    socket
  end

  def assign_created_shared_record_uuid(%{assigns: %{opened_records: opened_records, current_user: user, current_subscription: subscription}} = socket, record_id) do
    [record, _connected_records] = find_record_in_opened_records(opened_records, String.to_integer(record_id))
    %{id: uuid} = SharedRecords.create_record!(subscription.id, user.id, record.id)
    assign(socket, current_shared_record_uuid: uuid)
  end

  def assign_opened_records_after_record_update(%{assigns: %{opened_records: []}} = socket, _), do: socket
  def assign_opened_records_after_record_update(%{assigns: %{opened_records: opened_records}} = socket, %{id: updated_record_id} = updated_record) do
    new_opened_records = reduce_opened_records_with_function(opened_records, fn record ->
      case record.id do
        ^updated_record_id ->
          maybe_send_assign_connected_records(record, updated_record)

          updated_record
        _ -> record
      end
    end)

    assign(socket, opened_records: new_opened_records)
  end

  def assign_opened_records_after_delete(%{assigns: %{opened_records: []}} = socket, _), do: socket
  def assign_opened_records_after_delete(%{assigns: %{opened_records: opened_records}} = socket, id) when is_number(id) do
    assign(socket, opened_records: reduce_opened_records_with_function(opened_records, fn record -> unless(id == record.id, do: record) end))
  end

  def assign_opened_records_after_delete(%{assigns: %{opened_records: opened_records}} = socket, ids) when is_list(ids) do
    assign(socket, opened_records: reduce_opened_records_with_function(opened_records, fn record -> unless(Enum.member?(ids, record.id), do: record) end))
  end

  def toggle_opened_record_in_list([], opened_record), do: [opened_record]
  def toggle_opened_record_in_list(list, [%{id: record_id}, _] = opened_record) do
    case Enum.find_index(list, fn [%{id: id}, _connected_records] -> record_id == id end) do
      nil -> [opened_record | list]
      idx ->  List.delete_at(list, idx)
    end
  end

  def dispatch_delete_selected_records(%{assigns: %{opened_records: opened_records, current_subscription: subscription, table_id: table_id}} = socket) do
    ids = Enum.map(opened_records, fn [record, _connected_records] -> record.id end)
    {:ok, _deleted_count} = batch_delete_records(subscription, table_id, ids)

    socket
  end

  defp reduce_opened_records_with_function(opened_records, function) do
    Enum.reduce(opened_records, [], fn [record, connected_records], acc_list ->
      case function.(record) do
        nil -> acc_list
        reduced_record -> acc_list ++ [
            [reduced_record, reduce_list_with_function(connected_records, function)]
          ]
      end
    end)
  end

  def assign_opened_record_and_fetch_connected_records(%{assigns: %{records: records, opened_records: opened_records, current_subscription: subscription}} = socket, record_id) when length(opened_records) < 50 do
    record = find_record_in_list_or_database(subscription, records, record_id)
    opened_records = toggle_opened_record_in_list(opened_records, [record, []])

    send(self(), {:assign_connected_records_to_opened_record, record.id, record.connected_deer_records_ids})

    assign(socket, opened_records: opened_records)
  end

  def handle_disconnecting_records(%{assigns: %{opened_records: opened_records, current_subscription: subscription}} = socket, record1_id, record2_id) do
    [record1, connected_records] = find_record_in_opened_records(opened_records, String.to_integer(record1_id))
    record2 = Enum.find(connected_records, fn record -> record.id == record2_id end)

    disconnect_records!(record1, record2, subscription.id)

    socket
  end

  def assign_connected_records_to_opened_record(socket, _record_id, []), do: socket
  def assign_connected_records_to_opened_record(%{assigns: %{current_subscription: subscription, opened_records: opened_records}} = socket, record_id, ids) do
    new_opened_records = update_opened_record_with_connected_records(opened_records, record_id, get_records!(subscription.id, ids))

    assign(socket, opened_records: new_opened_records)
  end

  defp maybe_send_assign_connected_records(%DeerRecord{connected_deer_records_ids: list}, %DeerRecord{connected_deer_records_ids: list}), do: nil
  defp maybe_send_assign_connected_records(_old_record, %DeerRecord{connected_deer_records_ids: connected_records_ids} = new_record) do
    send(self(), {:assign_connected_records_to_opened_record, new_record.id, connected_records_ids})
  end

  defp update_opened_record_with_connected_records(list, id, connected_records) do
    case Enum.find_index(list, fn [%{id: record_id}, _old_connected_record] -> id == record_id end) do
      nil -> list # this is neccessary due to race condition after toggling two times quickly
      idx ->
        [record, _old_connected_records] = Enum.at(list, idx)
        List.replace_at(list, idx, [record, connected_records])
    end
  end

  defp find_record_in_opened_records(opened_records, record_id) do
    Enum.find(opened_records, fn [record, _connected_records] -> record.id == record_id end)
  end
end
