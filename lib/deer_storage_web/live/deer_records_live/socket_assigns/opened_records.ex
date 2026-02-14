defmodule DeerStorageWeb.DeerRecordsLive.Index.SocketAssigns.OpenedRecords do
  alias DeerStorageWeb.Router.Helpers, as: Routes
  alias DeerStorage.DeerRecords.DeerRecord
  alias DeerStorage.SharedRecords
  alias DeerStorage.SharedFiles

  import Phoenix.Component, only: [assign: 2, assign: 3]
  import Phoenix.LiveView, only: [push_navigate: 2]

  import DeerStorageWeb.DeerRecordView, only: [mimetype_is_previewable?: 1]

  import DeerStorageWeb.DeerRecordsLive.Index.SocketAssigns.Helpers,
    only: [
      assign_previous_previewable: 3,
      assign_next_previewable: 3,
      find_record_in_list_or_database: 4,
      find_record_in_opened_records: 2,
      find_record_in_opened_or_connected_records: 2,
      reduce_list_with_function: 2
    ]

  import DeerStorage.DeerRecords,
    only: [
      ensure_deer_file_exists_in_record!: 2,
      batch_delete_records: 3,
      delete_file_from_record!: 3,
      delete_record: 2,
      disconnect_records!: 3,
      get_records!: 2
    ]

  def assign_opened_record_from_params(socket, nil), do: socket

  def assign_opened_record_from_params(socket, record_id) when is_binary(record_id) do
    assign_opened_record_and_fetch_connected_records(socket, record_id)
  rescue
    Ecto.NoResultsError ->
      push_navigate(socket,
        to:
          Routes.live_path(
            DeerStorageWeb.Endpoint,
            DeerStorageWeb.DeerRecordsLive.Index,
            socket.assigns.table_id
          )
      )
  end

  def dispatch_delete_record(
        %{assigns: %{opened_records: opened_records, current_subscription: subscription}} = socket,
        record_id
      ) do
    [record, _connected_records] =
      find_record_in_opened_records(opened_records, String.to_integer(record_id))

    {:ok, _} = delete_record(subscription, record)

    socket
  end

  def dispatch_delete_file(
        %{assigns: %{current_subscription: %{id: subscription_id}}} = socket,
        record_id,
        file_id
      ) do
    delete_file_from_record!(subscription_id, record_id, file_id)

    socket
  end

  def assign_created_shared_record_for_editing_uuid(
        %{
          assigns: %{
            opened_records: opened_records,
            current_user: user,
            current_subscription: subscription
          }
        } = socket,
        record_id
      ) do
    [record, _connected_records] =
      find_record_in_opened_records(opened_records, String.to_integer(record_id))

    %{id: uuid} = SharedRecords.create_record_for_editing!(subscription.id, user.id, record.id)
    assign(socket, :current_shared_link, shared_link_for_record(subscription.id, uuid))
  end

  def assign_created_shared_record_uuid(
        %{
          assigns: %{
            opened_records: opened_records,
            current_user: user,
            current_subscription: subscription
          }
        } = socket,
        record_id
      ) do
    [record, _connected_records] =
      find_record_in_opened_records(opened_records, String.to_integer(record_id))

    %{id: uuid} = SharedRecords.create_record!(subscription.id, user.id, record.id)
    assign(socket, :current_shared_link, shared_link_for_record(subscription.id, uuid))
  end

  def assign_created_shared_file_uuid(
        %{
          assigns: %{
            opened_records: opened_records,
            current_user: user,
            current_subscription: subscription
          }
        } = socket,
        record_id,
        file_id
      ) do
    [record, _connected_records] =
      find_record_in_opened_records(opened_records, String.to_integer(record_id))

    ensure_deer_file_exists_in_record!(record, file_id)

    %{id: uuid} = SharedFiles.create_file!(subscription.id, user.id, record.id, file_id)
    assign(socket, :current_shared_link, shared_link_for_file(subscription.id, uuid, file_id))
  end

  def assign_preview_modal(
        %{assigns: %{opened_records: opened_records}} = socket,
        record_id,
        file_id
      ) do
    record_id = String.to_integer(record_id)
    record = find_record_in_opened_or_connected_records(opened_records, record_id)
    deer_file = ensure_deer_file_exists_in_record!(record, file_id)
    mimetype_is_previewable?(deer_file.mimetype) || raise "invalid preview requested"

    assign(socket, preview_for_record_id: record_id, preview_deer_file: deer_file)
  end

  def close_preview_modal(socket),
    do: assign(socket, preview_for_record_id: nil, preview_deer_file: nil)

  def preview_next_file(
        %{
          assigns: %{
            opened_records: opened_records,
            preview_for_record_id: record_id,
            preview_deer_file: %{id: current_deer_file_id}
          }
        } = socket
      ) do
    %{deer_files: all_deer_files} =
      find_record_in_opened_or_connected_records(opened_records, record_id)

    assign_next_previewable(socket, all_deer_files, current_deer_file_id)
  end

  def preview_previous_file(
        %{
          assigns: %{
            opened_records: opened_records,
            preview_for_record_id: record_id,
            preview_deer_file: %{id: current_deer_file_id}
          }
        } = socket
      ) do
    %{deer_files: all_deer_files} =
      find_record_in_opened_or_connected_records(opened_records, record_id)

    assign_previous_previewable(socket, all_deer_files, current_deer_file_id)
  end

  def maybe_close_preview_window_after_record_update(
        %{
          assigns: %{
            preview_for_record_id: record_id,
            preview_deer_file: %{id: preview_deer_file_id}
          }
        } = socket,
        %{id: record_id} = new_record
      ) do
    case Enum.find(new_record.deer_files, fn df -> df.id == preview_deer_file_id end) do
      nil -> assign(socket, preview_deer_file: nil, preview_for_record_id: nil)
      _ -> socket
    end
  end

  def maybe_close_preview_window_after_record_update(socket, _record), do: socket

  def maybe_close_preview_window_after_record_delete(
        %{assigns: %{preview_for_record_id: id}} = socket,
        id
      )
      when is_number(id) do
    assign(socket, preview_deer_file: nil, preview_for_record_id: nil)
  end

  def maybe_close_preview_window_after_record_delete(
        %{assigns: %{preview_for_record_id: id}} = socket,
        ids
      )
      when is_list(ids) do
    case Enum.member?(ids, id) do
      true -> assign(socket, preview_deer_file: nil, preview_for_record_id: nil)
      false -> socket
    end
  end

  def maybe_close_preview_window_after_record_delete(socket, _id_or_ids), do: socket

  def assign_invalidated_shared_records_for_record(
        %{assigns: %{opened_records: opened_records, current_subscription: subscription}} = socket,
        record_id
      ) do
    [record, _connected_records] =
      find_record_in_opened_records(opened_records, String.to_integer(record_id))

    SharedRecords.delete_all_by_deer_record_id!(subscription.id, record.id)
    SharedFiles.delete_all_by_deer_record_id!(subscription.id, record.id)

    socket
  end

  def assign_opened_records_after_record_update(%{assigns: %{opened_records: []}} = socket, _),
    do: socket

  def assign_opened_records_after_record_update(
        %{assigns: %{opened_records: opened_records}} = socket,
        %{id: updated_record_id} = updated_record
      ) do
    new_opened_records =
      reduce_opened_records_with_function(opened_records, fn record ->
        case record.id do
          ^updated_record_id ->
            maybe_send_assign_connected_records(record, updated_record)

            updated_record

          _ ->
            record
        end
      end)

    assign(socket, :opened_records, new_opened_records)
  end

  def assign_opened_records_after_delete(%{assigns: %{opened_records: []}} = socket, _),
    do: socket

  def assign_opened_records_after_delete(
        %{assigns: %{opened_records: opened_records}} = socket,
        id
      )
      when is_number(id) do
    assign(
      socket,
      :opened_records,
      reduce_opened_records_with_function(opened_records, fn record ->
        unless(id == record.id, do: record)
      end)
    )
  end

  def assign_opened_records_after_delete(
        %{assigns: %{opened_records: opened_records}} = socket,
        ids
      )
      when is_list(ids) do
    assign(
      socket,
      :opened_records,
      reduce_opened_records_with_function(opened_records, fn record ->
        unless(Enum.member?(ids, record.id), do: record)
      end)
    )
  end

  def toggle_opened_record_in_list([], opened_record), do: [opened_record]

  def toggle_opened_record_in_list(list, [%{id: record_id}, _] = opened_record) do
    case Enum.find_index(list, fn [%{id: id}, _connected_records] -> record_id == id end) do
      nil -> [opened_record | list]
      idx -> List.delete_at(list, idx)
    end
  end

  def dispatch_delete_selected_records(
        %{
          assigns: %{
            opened_records: opened_records,
            current_subscription: subscription,
            table_id: table_id
          }
        } = socket
      ) do
    ids = Enum.map(opened_records, fn [record, _connected_records] -> record.id end)
    {:ok, _deleted_count} = batch_delete_records(subscription, table_id, ids)

    socket
  end

  defp reduce_opened_records_with_function(opened_records, function) do
    Enum.reduce(opened_records, [], fn [record, connected_records], acc_list ->
      case function.(record) do
        nil ->
          acc_list

        reduced_record ->
          acc_list ++
            [
              [reduced_record, reduce_list_with_function(connected_records, function)]
            ]
      end
    end)
  end

  def assign_opened_record_and_fetch_connected_records(
        %{
          assigns: %{
            records: records,
            opened_records: opened_records,
            current_subscription: subscription,
            table_id: table_id
          }
        } = socket,
        record_id
      )
      when length(opened_records) < 100 do
    record = find_record_in_list_or_database(subscription, records, record_id, table_id)
    opened_records = toggle_opened_record_in_list(opened_records, [record, []])

    send(
      self(),
      {:assign_connected_records_to_opened_record, record, record.connected_deer_records_ids}
    )

    assign(socket, :opened_records, opened_records)
  end

  def assign_opened_record_and_fetch_connected_records(socket, _), do: socket

  def handle_disconnecting_records(
        %{assigns: %{opened_records: opened_records, current_subscription: subscription}} = socket,
        record1_id,
        record2_id
      ) do
    [record1, connected_records] = find_record_in_opened_records(opened_records, record1_id)
    record2 = Enum.find(connected_records, fn record -> record.id == record2_id end)

    disconnect_records!(record1, record2, subscription.id)

    socket
  end

  def assign_connected_records_to_opened_record(
        %{assigns: %{current_subscription: subscription, opened_records: opened_records}} = socket,
        %{id: record_id} = record,
        ids
      ) do
    connected_records_from_database = get_records!(subscription.id, ids)

    new_opened_records =
      update_opened_record_with_connected_records(
        opened_records,
        record_id,
        connected_records_from_database
      )

    send(
      self(),
      {:remove_orphans_after_receiveing_connected_records, record,
       connected_records_from_database}
    )

    assign(socket, :opened_records, new_opened_records)
  end

  defp maybe_send_assign_connected_records(
         %DeerRecord{connected_deer_records_ids: list},
         %DeerRecord{connected_deer_records_ids: list}
       ),
       do: nil

  defp maybe_send_assign_connected_records(
         _old_record,
         %DeerRecord{connected_deer_records_ids: connected_records_ids} = new_record
       ) do
    send(self(), {:assign_connected_records_to_opened_record, new_record, connected_records_ids})
  end

  defp update_opened_record_with_connected_records(list, id, connected_records) do
    case Enum.find_index(list, fn [%{id: record_id}, _old_connected_record] -> id == record_id end) do
      # this is neccessary due to race condition after toggling two times quickly
      nil ->
        list

      idx ->
        [record, _old_connected_records] = Enum.at(list, idx)
        List.replace_at(list, idx, [record, connected_records])
    end
  end

  defp shared_link_for_record(subscription_id, record_uuid) do
    Routes.live_url(
      DeerStorageWeb.Endpoint,
      DeerStorageWeb.SharedRecordsLive.Show,
      subscription_id,
      record_uuid
    )
  end

  defp shared_link_for_file(subscription_id, shared_file_uuid, file_id) do
    Routes.shared_record_files_url(
      DeerStorageWeb.Endpoint,
      :download_file_from_shared_file,
      subscription_id,
      shared_file_uuid,
      file_id
    )
  end
end
