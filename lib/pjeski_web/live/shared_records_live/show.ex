defmodule PjeskiWeb.SharedRecordsLive.Show do
  use Phoenix.LiveView

  import PjeskiWeb.LiveHelpers, only: [is_expired?: 1]

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
        shared_record = SharedRecords.get_record!(subscription_id, shared_record_uuid) |> Pjeski.Repo.preload(:deer_record)
        deer_record = shared_record.deer_record

        PubSub.subscribe(Pjeski.PubSub, "records:#{subscription_id}")
        PubSub.subscribe(Pjeski.PubSub, "subscription:#{subscription_id}")

        {:noreply, assign(socket, deer_record: deer_record, subscription: subscription, shared_record: shared_record)}
      false -> {:noreply, socket}
    end

    rescue Ecto.NoResultsError -> {:noreply, push_redirect(socket, to: "/")}
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
    {:noreply, socket |> assign(deer_record: updated_deer_record)}
  end
  def handle_info({:record_update, _}, socket), do: {:noreply, socket}

  def handle_info({:subscription_updated, subscription}, %{assigns: %{deer_record: %{deer_table_id: deer_table_id}}} = socket) do
    case is_expired?(subscription) do
      true -> {:noreply, push_redirect(socket, to: "/")}
      false ->
        case DeerRecordView.deer_table_from_subscription(subscription, deer_table_id) do
          nil -> {:noreply, push_redirect(socket, to: "/")}
          _ -> {:noreply, assign(socket, subscription: subscription)}
       end
     end
   end
end
