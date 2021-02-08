defmodule PjeskiWeb.DeerRecordsLive.Index do
  use Phoenix.LiveView
  alias Phoenix.PubSub
  alias PjeskiWeb.Router.Helpers, as: Routes

  import Pjeski.Users.UserSessionUtils, only: [get_live_user: 2]
  import PjeskiWeb.DeerRecordsLive.Index.SocketAssigns.{Subscription, EditingRecord, NewRecord, NewConnectedRecord, Records, OpenedRecords, ConnectingRecords, UploadingFiles}
  import Pjeski.DbHelpers.DeerRecordsSearch, only: [per_page: 0, prepare_search_query: 1]

  def mount(_params, %{"pjeski_auth" => token, "current_subscription_id" => subscription_id} = session, socket) do
    user = get_live_user(socket, session)
    Gettext.put_locale(user.locale)

    if connected?(socket), do: subscribe_to_user_channels(token, user.id)

    {:ok, assign_initial_data(socket, user, subscription_id)}
  end

  def render(assigns), do: PjeskiWeb.DeerRecordView.render("index.html", assigns)

  def handle_params(%{"table_id" => table_id} = params, _, %{assigns: %{current_user: user, current_subscription_id: subscription_id}} = socket) do
    case connected?(socket) do
      true ->
        subscribe_to_deer_channels(subscription_id, table_id)

        {:noreply,
         socket
         |> assign_subscription_if_available_subscription_link_exists!(user.id, subscription_id)
         |> assign_table_or_redirect_to_dashboard!(table_id)
         |> maybe_assign_first_search_query(prepare_search_query(params["query"]))
         |> assign_opened_record_from_params(params["id"])
        }
      false -> {:noreply, socket |> assign(query: "", records: [], count: 0)}
    end
  end

  def handle_event("close_show", %{"id" => id_string}, %{assigns: %{opened_records: opened_records}} = socket) do
    {:noreply, socket |> assign(opened_records: toggle_opened_record_in_list(opened_records, [%{id: String.to_integer(id_string)}, []]))}
  end

  def handle_event("close_new_connected_record", _, socket), do: {:noreply, assign_closed_new_connected_record_modal(socket)}
  def handle_event("close_new", _, socket), do: {:noreply, socket |> assign(new_record: nil)}
  def handle_event("close_shared_link", _, socket), do: {:noreply, socket |> assign(current_shared_link: nil)}
  def handle_event("close_connecting_record", _, socket), do: {:noreply, assign_closed_connecting_records(socket)}
  def handle_event("close_edit", _, socket), do: {:noreply, assign_closed_editing_record(socket)}
  def handle_event("close_upload_file_modal", _, socket), do: {:noreply, assign_closed_file_upload_modal(socket)}
  def handle_event("clear_selected", _, socket), do: {:noreply, assign(socket, :opened_records, [])}

  def handle_event("validate_edit", %{"deer_record" => attrs}, socket), do: {:noreply, assign_editing_record(socket, attrs)}
  def handle_event("validate_new", %{"deer_record" => attrs}, socket), do: {:noreply, assign_new_record(socket, attrs)}
  def handle_event("validate_new_connected_record", %{"deer_record" => attrs}, socket), do: {:noreply, assign_new_connected_record(socket, attrs)}
  def handle_event("save_edit", %{"deer_record" => attrs}, socket), do: {:noreply, assign_saved_editing_record(socket, attrs)}
  def handle_event("save_new", %{"deer_record" => attrs}, socket), do: {:noreply, assign_created_record(socket, attrs)}
  def handle_event("save_new_connected_record", %{"deer_record" => attrs}, socket), do: {:noreply, assign_created_connected_record(socket, attrs)}
  def handle_event("move_editing_record_data_to_new_record", _, socket), do: {:noreply, socket |> copy_editing_record_to_new_record}

  def handle_event("new_connected_record", %{"connecting-with-record_id" => id}, socket), do: {:noreply, assign_opened_new_connected_record_modal(socket, String.to_integer(id))}
  def handle_event("show_connect_record_modal", %{"record_id" => record_id}, socket), do: {:noreply, assign_modal_for_connecting_records(socket, record_id)}
  def handle_event("show", %{"record_id" => record_id}, socket), do: {:noreply, assign_opened_record_and_fetch_connected_records(socket, record_id)}
  def handle_event("new", _, socket), do: {:noreply, assign_opened_new_record_modal(socket)}
  def handle_event("edit", %{"record_id" => record_id}, socket), do: {:noreply, assign_opened_edit_record_modal(socket, record_id)}
  def handle_event("show_upload_file_modal", %{"record_id" => record_id, "table_id" => table_id}, socket), do: {:noreply, assign_opened_file_upload_modal(socket, table_id, record_id)}

  def handle_event("share", %{"record_id" => record_id}, socket), do: {:noreply, assign_created_shared_record_uuid(socket, record_id)}
  def handle_event("share-for-editing", %{"record_id" => record_id}, socket), do: {:noreply, assign_created_shared_record_for_editing_uuid(socket, record_id)}
  def handle_event("invalidate-shared-links", %{"record_id" => record_id}, socket), do: {:noreply, assign_invalidated_shared_records_for_record(socket, record_id)}
  def handle_event("share_record_file", %{"file-id" => file_id, "record-id" => record_id}, socket), do: {:noreply, assign_created_shared_file_uuid(socket, record_id, file_id)}

  def handle_event("connecting_record_filter", %{"query" => query, "table_id" => new_table_id}, socket) when byte_size(query) <= 50, do: {:noreply, assign_filtered_connected_records(socket, prepare_search_query(query), new_table_id)}
  def handle_event("connect_records", %{"record_id" => record_id}, socket), do: {:noreply, handle_connecting_records(socket, String.to_integer(record_id))}
  def handle_event("disconnect_records", %{"opened_record_id" => opened_record_id, "connected_record_id" => connected_record_id}, socket) do
    {:noreply, handle_disconnecting_records(socket, String.to_integer(opened_record_id), String.to_integer(connected_record_id))}
  end

  def handle_event("delete_selected", _, socket), do: {:noreply, dispatch_delete_selected_records(socket)}
  def handle_event("delete", %{"record_id" => record_id}, socket), do: {:noreply, dispatch_delete_record(socket, record_id)}
  def handle_event("delete_record_file", %{"file-id" => file_id, "record-id" => record_id}, socket), do: {:noreply, dispatch_delete_file(socket, record_id, file_id)}
  def handle_event("validate_upload", _, socket), do: {:noreply, socket |> assign(:upload_results, []) |> cancel_all_uploads_if_limit_is_exceeded}

  def handle_event("cancel_upload_entry", %{"ref" => ref}, socket), do: {:noreply, cancel_upload(socket, :deer_file, ref)}
  def handle_event("submit_upload", _, socket), do: {:noreply, assign_submitted_upload(socket, self())}

  def handle_event("clear", _, socket), do: {:noreply, run_search_query_and_assign_results(socket, [], 1)}

  def handle_event("filter", %{"query" => query}, socket) when byte_size(query) <= 50, do: {:noreply, run_search_query_and_assign_results(socket, prepare_search_query(query), 1)}

  def handle_event("next_page", _, %{assigns: %{page: page}} = socket), do: {:noreply, change_page(socket, page + 1)}
  def handle_event("previous_page", _, %{assigns: %{page: page}} = socket), do: {:noreply, change_page(socket, page - 1)}

  def handle_event("change_new_connected_record_table_id", %{"table_id" => table_id}, socket) do
    {:noreply, assign_overwritten_table_id_in_new_record(socket, table_id)}
  end

  def handle_event("redirect_to_connected_record", %{"record_id" => record_id, "table_id" => table_id}, socket) do
    {:noreply, push_redirect(socket, to: Routes.live_path(PjeskiWeb.Endpoint, PjeskiWeb.DeerRecordsLive.Index, table_id, id: record_id))}
  end

  def handle_call(:whats_my_table_id, _pid, %{assigns: %{table_id: table_id}} = socket), do: {:reply, table_id, socket}
  def handle_info(:logout, socket), do: {:noreply, push_redirect(socket, to: "/")}
  def handle_info({:subscription_updated, subscription}, socket), do: {:noreply, socket |> assign_updated_subscription(subscription) |> maybe_reload_and_overwrite_deer_file_upload}
  def handle_info({:cached_records_count_changed, _table_id, new_count}, %{assigns: %{cached_count: _}} = socket), do: {:noreply, socket |> assign(cached_count: new_count) |> assign_search_debounce}
  def handle_info({:assign_connected_records_to_opened_record, record, ids}, socket), do: {:noreply, assign_connected_records_to_opened_record(socket, record, ids)}
  def handle_info({:remove_orphans_after_receiveing_connected_records, record, records}, socket), do: {:noreply, remove_orphans_after_receiveing_connected_records(socket, record, records)}

  def handle_info({:batch_record_delete, deleted_records_ids}, socket), do: {:noreply, remove_record_from_assigns(socket, deleted_records_ids)}
  def handle_info({:record_delete, deleted_record_id}, socket), do: {:noreply, remove_record_from_assigns(socket, deleted_record_id)}

  def handle_info({:record_update, %{deer_table_id: table_id} = record}, %{assigns: %{table_id: table_id}} = socket) do
    socket = socket
    |> assign_records_after_update(record)
    |> assign_connecting_records_after_update(record)
    |> assign_opened_records_after_record_update(record)
    |> assign_editing_record_after_update(record)
    |> assign_uploading_file_for_record_after_update(record)

    {:noreply, socket}
  end

  def handle_info({:record_update, record}, socket) do
    socket = socket
    |> assign_opened_records_after_record_update(record)
    |> assign_connecting_records_after_update(record)

    {:noreply, socket}
  end

  def handle_cast({:upload_deer_file_result, {filename, {:ok, _}}}, socket), do: {:noreply, assign_upload_result(socket, {:ok, filename})}
  def handle_cast({:upload_deer_file_result, {filename, {:error, _}}}, socket), do: {:noreply, assign_upload_result(socket, {:error, filename})}

  defp remove_record_from_assigns(socket, id_or_ids) do
    socket
    |> assign_records_and_count_after_delete(id_or_ids)
    |> assign_opened_records_after_delete(id_or_ids)
    |> assign_connecting_records_after_delete(id_or_ids)
    |> assign_editing_record_after_delete(id_or_ids)
    |> assign_uploading_file_for_record_after_delete(id_or_ids)
    |> maybe_close_new_connected_record_modal(id_or_ids)
  end

  defp assign_initial_data(socket, user, current_subscription_id) do
    assign(socket,
      opened_records: [],
      editing_record: nil,
      editing_record_has_been_removed: false,
      old_editing_record: nil,
      new_record: nil,
      new_connected_record: nil,
      new_record_connecting_with_record_id: nil,
      table_name: nil,
      page: 1,
      per_page: per_page(),
      cached_count: 0,
      current_user: user,
      current_subscription: nil,
      current_subscription_id: current_subscription_id,
      current_subscription_name: nil,
      current_subscription_tables: nil,
      current_subscription_deer_records_per_table_limit: 0,
      current_shared_link: nil,
      connecting_record: nil,
      connecting_query: nil,
      connecting_records: [],
      connecting_selected_table_id: nil,
      storage_limit_kilobytes: 0,
      uploading_file_for_record: nil,
      upload_results: [],
      locale: user.locale,
      search_debounce: "0",
    )
  end

  defp subscribe_to_user_channels(token, user_id) do
    PubSub.subscribe(Pjeski.PubSub, "session_#{token}")
    PubSub.subscribe(Pjeski.PubSub, "user_#{user_id}")
  end

  defp subscribe_to_deer_channels(subscription_id, table_id) do
    PubSub.subscribe(Pjeski.PubSub, "records:#{subscription_id}")
    PubSub.subscribe(Pjeski.PubSub, "subscription:#{subscription_id}")
    PubSub.subscribe(Pjeski.PubSub, "records_counts:#{table_id}")
  end
end
