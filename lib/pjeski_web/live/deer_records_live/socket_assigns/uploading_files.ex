defmodule PjeskiWeb.DeerRecordsLive.Index.SocketAssigns.UploadingFiles do
  @tmp_dir System.tmp_dir!()

  import Phoenix.LiveView, only: [assign: 3, allow_upload: 3, consume_uploaded_entry: 3, consume_uploaded_entries: 3, uploaded_entries: 2, cancel_upload: 3]
  import PjeskiWeb.DeerRecordView, only: [deer_table_from_subscription: 2]
  import PjeskiWeb.DeerRecordsLive.Index.SocketAssigns.Helpers, only: [any_entry_started_upload?: 1]

  def assign_uploading_file_for_record_after_update(%{assigns: %{uploading_file_for_record: %{id: record_id}}} = socket, %{id: record_id} = updated_record) do
    socket |> assign(:uploading_file_for_record, updated_record) |> reload_subscription_storage_and_allow_upload
  end
  def assign_uploading_file_for_record_after_update(socket, _), do: maybe_reload_and_overwrite_deer_file_upload(socket)

  def assign_uploading_file_for_record_after_delete(%{assigns: %{uploading_file_for_record: nil}} = socket, _), do: maybe_reload_and_overwrite_deer_file_upload(socket)
  def assign_uploading_file_for_record_after_delete(%{assigns: %{uploading_file_for_record: %{id: id}}} = socket, ids) when is_list(ids) do
    socket = case Enum.member?(ids, id) do
               true -> assign_closed_file_upload_modal(socket)
               false -> socket
             end

    reload_subscription_storage_and_allow_upload(socket)
  end
  def assign_uploading_file_for_record_after_delete(%{assigns: %{uploading_file_for_record: %{id: id}}} = socket, id) do
    assign_closed_file_upload_modal(socket) |> reload_subscription_storage_and_allow_upload
  end
  def assign_uploading_file_for_record_after_delete(socket, _id), do: socket

  def assign_closed_file_upload_modal(socket) do
    cancel_all_entries_in_socket(socket)
    |> assign(:uploading_file_for_record, nil)
    |> assign(:upload_results, [])
  end

  def assign_opened_file_upload_modal(%{assigns: %{opened_records: opened_records, current_subscription: subscription}} = socket, table_id, record_id) do
    deer_table_from_subscription(subscription, table_id) || raise "invalid table id"
    uploading_record = find_record_in_opened_or_connected_records(opened_records, String.to_integer(record_id))

    socket |> reload_subscription_storage_and_allow_upload |> assign(:uploading_file_for_record, uploading_record)
  end

  def assign_submitted_upload(%{assigns: %{current_user: %{id: user_id}, uploading_file_for_record: %{id: record_id}}} = socket, pid) do
    consume_uploaded_entries(socket, :deer_file, fn %{path: path}, %{client_name: original_filename, uuid: uuid} ->
      tmp_path = Path.join(@tmp_dir, uuid)
      File.rename!(path, tmp_path)

      spawn(Pjeski.Services.UploadDeerFile, :run!, [pid, tmp_path, original_filename, record_id, user_id, uuid])
    end)

    socket |> assign(:upload_results, [])
  end

  def maybe_reload_and_overwrite_deer_file_upload(%{assigns: %{uploads: %{deer_file: _deer_file}}} = socket), do: reload_subscription_storage_and_allow_upload(socket)
  def maybe_reload_and_overwrite_deer_file_upload(socket), do: socket

  def reload_subscription_storage_and_allow_upload(%{assigns: %{current_subscription: %{id: subscription_id, deer_files_limit: total_files_limit, storage_limit_kilobytes: storage_limit_kilobytes}}} = socket) do
    {files_count, used_storage_kilobytes} = DeerCache.SubscriptionStorageCache.fetch_data(subscription_id)

    space_left = (ceil(storage_limit_kilobytes) - used_storage_kilobytes) * 1024
    files_left = total_files_limit - files_count

    case socket.assigns do
      %{uploads: %{deer_file: %{entries: []}}} -> allow_deer_file_upload_or_overwrite_existing(socket, files_left, space_left)
      %{uploads: %{deer_file: %{entries: entries}}} ->
        case any_entry_started_upload?(entries) do
          true -> if limit_is_exceeded?(socket, files_left, space_left), do: raise("limit exceeded"), else: socket
          false -> socket
        end
      _ -> allow_deer_file_upload_or_overwrite_existing(socket, files_left, space_left)
    end
  end

  def assign_upload_result(%{assigns: %{upload_results: results}} = socket, message), do: assign(socket, :upload_results, [message | results])
  def assign_upload_result(socket, message), do: assign(socket, :upload_results, [message])

  def cancel_all_uploads_if_limit_is_exceeded(%{assigns: %{uploads: %{deer_file: %{max_entries: files, max_file_size: size}}}} = socket) do
    if limit_is_exceeded?(socket, files, size) do
      cancel_all_entries_in_socket(socket) |> assign_upload_result(:total_size_exceeds_limits)
    else
      assign(socket, :upload_errors, [])
    end
  end

  def limit_is_exceeded?(%{assigns: %{uploads: %{deer_file: deer_file_uploads}}} = _socket, files_left, space_left) do
    {files_count, size} = Enum.reduce(deer_file_uploads.entries, {0, 0}, fn entry, {files_count, size} ->
      {files_count + 1, size + entry.client_size}
    end)

    (space_left - size < 0) || (files_left - files_count < 0)
  end

  defp cancel_all_entries_in_socket(socket) do
    {completed, in_progress} = uploaded_entries(socket, :deer_file)

    Enum.each(completed, fn entry -> consume_uploaded_entry(socket, entry, fn _ -> nil end) end)
    Enum.reduce(in_progress, socket, fn entry, socket_acc -> cancel_upload(socket_acc, :deer_file, entry.ref) end)
  end

  defp allow_deer_file_upload_or_overwrite_existing(%{assigns: %{uploads: %{deer_file: deer_file} = uploads}} = socket, files, size) do
    deer_file = Map.merge(deer_file, %{max_entries: files, max_file_size: size})
    uploads = Map.merge(uploads, %{deer_file: deer_file})

    assign(socket, :uploads, uploads)
  end

  defp allow_deer_file_upload_or_overwrite_existing(socket, files, size), do: allow_upload(socket, :deer_file, accept: :any, auto_upload: false, max_entries: files, max_file_size: size)

  defp find_record_in_opened_or_connected_records([], _record_id), do: raise "no opened records found"
  defp find_record_in_opened_or_connected_records([[%{id: id} = record, _] | _], id), do: record
  defp find_record_in_opened_or_connected_records([[_, connected_records] | rest], record_id) do
    find_record_in_list(connected_records, record_id) || find_record_in_opened_or_connected_records(rest, record_id)
  end

  defp find_record_in_list(records, id), do: Enum.find(records, fn record -> record.id == id end)
end
