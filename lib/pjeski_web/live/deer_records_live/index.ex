defmodule PjeskiWeb.DeerRecordsLive.Index do
  use Phoenix.LiveView

  import Pjeski.Users.UserSessionUtils, only: [get_live_user: 2]

  import PjeskiWeb.DeerRecordsLive.Index.Helpers

  def mount(_params, %{"pjeski_auth" => token, "current_subscription_id" => subscription_id} = session, socket) do
    user = get_live_user(socket, session)
    Gettext.put_locale(user.locale)

    if connected?(socket), do: subscribe_to_user_channels(token, user.id)

    {:ok, assign_initial_mount_data(socket, user, subscription_id)}
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
         |> assign_first_search_query_if_subscription_is_not_expired(params["query"])
        }
      false -> {:noreply, socket |> assign(query: "", records: [], count: 0)}
    end
  end

  def handle_event("close_show", %{"id" => id_string}, %{assigns: %{opened_records: opened_records}} = socket) do
    {:noreply, socket |> assign(opened_records: toggle_opened_record_in_list(opened_records, [%{id: String.to_integer(id_string)}, []]))}
  end

  def handle_event("close_new", _, socket), do: {:noreply, socket |> assign(new_record: nil)}
  def handle_event("close_shared_record", _, socket), do: {:noreply, socket |> assign(current_shared_record_uuid: nil)}
  def handle_event("close_connecting_record", _, socket), do: {:noreply, socket |> assign(currently_connecting_record_id: nil, currently_connecting_record_query: nil)}
  def handle_event("close_edit", _, socket), do: {:noreply, assign_closed_editing_record(socket)}
  def handle_event("clear_selected", _, socket), do: {:noreply, assign(socket, :opened_records, [])}

  def handle_event("validate_edit", %{"deer_record" => attrs}, socket), do: {:noreply, assign_editing_record(socket, attrs)}
  def handle_event("validate_new", %{"deer_record" => attrs}, socket), do: {:noreply, assign_new_record(socket, attrs)}
  def handle_event("save_edit", %{"deer_record" => attrs}, socket), do: {:noreply, assign_updated_record(socket, attrs)}
  def handle_event("save_new", %{"deer_record" => attrs}, socket), do: {:noreply, assign_saved_record(socket, attrs)}
  def handle_event("move_editing_record_data_to_new_record", _, socket) do
    {:noreply, socket |> copy_editing_record_to_new_record |> assign_closed_editing_record}
  end

  def handle_event("show_connect_record_modal", %{"record_id" => record_id}, socket), do: {:noreply, assign_modal_for_connecting_records(socket, record_id)}
  def handle_event("show", %{"record_id" => record_id}, socket), do: {:noreply, assign_opened_record_and_fetch_connected_records(socket, record_id)}
  def handle_event("new", _, socket), do: {:noreply, assign_opened_new_record_modal(socket)}
  def handle_event("edit", %{"record_id" => record_id}, socket), do: {:noreply, assign_opened_edit_record_modal(socket, record_id)}

  def handle_event("share", %{"record_id" => record_id}, socket), do: {:noreply, assign_created_shared_record_uuid(socket, record_id)}

  def handle_event("connecting_record_filter", %{"query" => query, "table_id" => new_table_id}, socket), do: {:noreply, assign_filtered_connected_records(socket, query, new_table_id)}
  def handle_event("connect_records", %{"record_id" => record_id}, socket), do: {:noreply, handle_connecting_records(socket, String.to_integer(record_id))}
  def handle_event("disconnect_records", %{"opened_record_id" => opened_record_id, "connected_record_id" => connected_record_id}, socket) do
    {:noreply, handle_disconnecting_records(socket, String.to_integer(opened_record_id), String.to_integer(connected_record_id))}
  end

  def handle_event("delete_selected", _, socket), do: {:noreply, handle_delete_all_opened_records(socket)}
  def handle_event("delete", %{"record_id" => record_id}, socket), do: {:noreply, handle_delete_record(socket, record_id)}
  def handle_event("delete_record_file", %{"file-id" => file_id, "record-id" => record_id}, socket), do: {:noreply, handle_file_delete(socket, record_id, file_id)}

  def handle_event("clear", _, socket), do: {:noreply, run_search_query_and_assign_results(socket, "", 1)}
  def handle_event("filter", %{"query" => query}, socket) when byte_size(query) <= 50, do: {:noreply, run_search_query_and_assign_results(socket, query, 1)}

  def handle_event("submit", %{"query" => query}, socket), do: {:noreply, assign(socket, :query, query)}

  def handle_event("next_page", _, %{assigns: %{page: page}} = socket), do: {:noreply, change_page(socket, page + 1)}
  def handle_event("previous_page", _, %{assigns: %{page: page}} = socket), do: {:noreply, change_page(socket, page - 1)}

  def handle_call(:whats_my_table_id, _pid, %{assigns: %{table_id: table_id}} = socket), do: {:reply, table_id, socket}
  def handle_info(:logout, socket), do: {:noreply, push_redirect(socket, to: "/")}
  def handle_info({:subscription_updated, subscription}, socket), do: {:noreply, assign_updated_subscription(socket, subscription)}
  def handle_info({:cached_records_count_changed, _table_id, new_count}, %{assigns: %{cached_count: _}} = socket), do: {:noreply, socket |> assign(cached_count: new_count)}
  def handle_info({:assign_connected_records_to_record, record_id, ids}, socket), do: {:noreply, assign_connected_records_to_record(socket, record_id, ids)}
  def handle_info({:batch_record_delete, deleted_records_ids}, socket), do: {:noreply, remove_record_from_assigns(socket, deleted_records_ids)}
  def handle_info({:record_delete, deleted_record_id}, socket), do: {:noreply, remove_record_from_assigns(socket, deleted_record_id)}

  def handle_info({:record_update, record}, socket) do
    socket = socket
    |> assign_records_after_update(record)
    |> assign_currently_connected_records_after_update(record)
    |> assign_opened_records_after_update(record)
    |> assign_editing_record_after_update(record)

    {:noreply, socket}
  end

  defp remove_record_from_assigns(socket, id_or_ids) do
    socket
    |> assign_records_and_count_after_delete(id_or_ids)
    |> assign_opened_records_after_delete(id_or_ids)
    |> assign_currently_connecting_records_and_count_after_delete(id_or_ids)
    |> assign_editing_record_after_delete(id_or_ids)
  end
end
