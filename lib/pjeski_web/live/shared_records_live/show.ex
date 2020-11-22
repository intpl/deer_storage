defmodule PjeskiWeb.SharedRecordsLive.Show do
  use Phoenix.LiveView
  import Ecto.Changeset, only: [fetch_field!: 2]

  import PjeskiWeb.LiveHelpers, only: [is_expired?: 1]
  import PjeskiWeb.DeerRecordsLive.Index.SocketAssigns.Helpers, only: [atomize_and_merge_table_id_to_attrs: 2, append_missing_fields_to_record: 3, overwrite_deer_fields: 2]
  import Pjeski.DeerRecords, only: [change_record: 3, update_record: 3]

  alias Phoenix.PubSub
  alias Pjeski.Subscriptions
  alias Pjeski.SharedRecords
  alias PjeskiWeb.DeerRecordView

  def mount(_params,  _session, socket), do: {:ok, assign(socket, deer_record: nil)}

  def render(assigns), do: DeerRecordView.render("show_external.html", assigns)

  def handle_params(%{"shared_record_uuid" => shared_record_uuid, "subscription_id" => subscription_id}, _, socket) do
    case connected?(socket) do
      true ->
        subscription_id = String.to_integer(subscription_id)
        subscription = Subscriptions.get_subscription!(subscription_id)

        redirect_if_expired(socket, subscription, fn ->
          shared_record = SharedRecords.get_record!(subscription_id, shared_record_uuid) |> Pjeski.Repo.preload(:deer_record)

          PubSub.subscribe(Pjeski.PubSub, "records:#{subscription_id}")
          PubSub.subscribe(Pjeski.PubSub, "subscription:#{subscription_id}")

          {:noreply, assign(socket,
              deer_record: shared_record.deer_record,
              old_editing_record: nil,
              subscription: subscription,
              shared_record: shared_record,
              is_editable: shared_record.is_editable,
              editing_record: nil)}
        end)
      false -> {:noreply, socket}
    end

    rescue Ecto.NoResultsError -> {:noreply, push_redirect(socket, to: "/")}
  end

  def handle_event("close_edit", _, %{assigns: %{is_editable: true}} = socket), do: {:noreply, assign(socket, editing_record: nil, old_editing_record: nil)}

  def handle_event("edit", _, %{assigns: %{deer_record: %{deer_table_id: table_id} = record, subscription: subscription, is_editable: true}} = socket) do
    {:noreply, assign(socket, editing_record: change_record(
          subscription,
          append_missing_fields_to_record(record, table_id, subscription),
          %{deer_table_id: table_id}
        )
    )}
  end

  def handle_event("validate_edit", %{"deer_record" => attrs}, %{assigns: %{deer_record: %{deer_table_id: table_id} = record, subscription: subscription, is_editable: true}} = socket) do
    {:noreply, assign(socket, editing_record: change_record(subscription, record, atomize_and_merge_table_id_to_attrs(attrs, table_id)))}
  end

  def handle_event("save_edit", %{"deer_record" => attrs}, %{assigns: %{deer_record: %{deer_table_id: table_id} = record, subscription: subscription, is_editable: true}} = socket) do
    atomized_attrs = atomize_and_merge_table_id_to_attrs(attrs, table_id)

    case update_record(subscription, record, atomized_attrs) do
      {:ok, _} -> {:noreply, assign(socket, editing_record: nil, old_editing_record: nil)}
      {:error, _} -> {:noreply, socket}
    end
  end

  def handle_info({:batch_record_delete, deleted_record_ids}, %{assigns: %{deer_record: %{id: deer_record_id}}} = socket) do
    case Enum.member?(deleted_record_ids, deer_record_id) do
      true -> {:noreply, push_redirect(socket, to: "/")}
      false -> {:noreply, socket}
    end
  end

  def handle_info({:record_delete, record_id}, %{assigns: %{deer_record: %{id: record_id}}} = socket), do: {:noreply, push_redirect(socket, to: "/")}
  def handle_info({:record_delete, _}, socket), do: {:noreply, socket}

  def handle_info({:record_update, %{id: record_id} = updated_deer_record}, %{assigns: %{deer_record: %{id: record_id}}} = socket) do
    {:noreply,
     socket
     |> assign(deer_record: updated_deer_record)
     |> assign_editing_deer_record_as_old_record(updated_deer_record)
    }
  end
  def handle_info({:record_update, _}, socket), do: {:noreply, socket}

  def handle_info({:subscription_updated, subscription}, %{assigns: %{deer_record: %{deer_table_id: deer_table_id}}} = socket) do
    redirect_if_expired(socket, subscription, fn ->
      case DeerRecordView.deer_table_from_subscription(subscription, deer_table_id) do
        nil -> {:noreply, push_redirect(socket, to: "/")}
        _ -> {:noreply, assign(socket, subscription: subscription)}
      end
    end)
   end

  defp assign_editing_deer_record_as_old_record(%{assigns: %{editing_record: %{data: %{id: record_id, deer_table_id: table_id}} = old_editing_record_changeset, subscription: subscription}} = socket, %{id: record_id} = record_in_database) do
    ch = overwrite_deer_fields(record_in_database, fetch_field!(old_editing_record_changeset, :deer_fields))
    new_editing_record_changeset = change_record(subscription, ch, %{deer_table_id: table_id})
    socket = assign(socket, editing_record: new_editing_record_changeset)

    case Enum.any?(DeerRecordView.different_deer_fields(new_editing_record_changeset, record_in_database)) do
      true -> assign(socket, old_editing_record: change_record(subscription, record_in_database, %{deer_table_id: table_id}))
      false -> socket
    end
  end

  defp assign_editing_deer_record_as_old_record(socket, _record), do: socket

  defp redirect_if_expired(socket, subscription, function_to_run) do
    case is_expired?(subscription) do
      true -> {:noreply, push_redirect(socket, to: "/")}
      false -> function_to_run.()
    end
  end
end
