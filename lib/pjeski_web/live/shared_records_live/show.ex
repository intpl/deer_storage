defmodule PjeskiWeb.SharedRecordsLive.Show do
  use Phoenix.LiveView

  import PjeskiWeb.Gettext
  import PjeskiWeb.LiveHelpers, only: [is_expired?: 1]

  alias Phoenix.PubSub
  alias Pjeski.Repo
  alias Pjeski.Subscriptions
  alias Pjeski.SharedRecords
  alias Pjeski.DeerRecords

  def mount(_params,  _session, socket), do: {:ok, assign(socket, deer_record: nil)}

  def render(assigns), do: PjeskiWeb.DeerRecordView.render("show_external.html", assigns)

  def handle_params(%{"shared_record_uuid" => shared_record_uuid, "subscription_id" => subscription_id}, _, socket) do
    case connected?(socket) do
      true ->
        subscription_id = String.to_integer(subscription_id)
        subscription = Subscriptions.get_subscription!(subscription_id)

        shared_record = SharedRecords.get_record!(subscription_id, shared_record_uuid)
        deer_record = DeerRecords.get_record!(subscription_id, shared_record.deer_record_id)

        {:noreply, assign(socket,
            deer_record: deer_record,
            subscription: subscription,
            shared_record: shared_record
          )
        }
      false -> {:noreply, socket}
    end
  end
end
