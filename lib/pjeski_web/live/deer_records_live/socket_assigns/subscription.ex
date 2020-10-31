defmodule PjeskiWeb.DeerRecordsLive.Index.SocketAssigns.Subscription do
  alias Pjeski.UserAvailableSubscriptionLinks.UserAvailableSubscriptionLink
  alias Pjeski.Repo
  import Phoenix.LiveView, only: [assign: 2, assign: 3, push_redirect: 2]
  import PjeskiWeb.LiveHelpers, only: [is_expired?: 1]
  import PjeskiWeb.DeerRecordView, only: [deer_table_from_subscription: 2]
  import Pjeski.DeerRecords, only: [change_record: 3]

  def assign_table_or_redirect_to_dashboard!(%{assigns: %{current_subscription: subscription}} = socket, table_id) do
    case deer_table_from_subscription(subscription, table_id) do
      %{name: table_name} -> assign(socket, table_name: table_name, table_id: table_id)
      nil -> push_redirect(socket, to: "/dashboard")
    end
  end

  def assign_subscription_if_available_subscription_link_exists!(socket, user_id, subscription_id) do
    user_subscription_link = UserAvailableSubscriptionLink
    |> Repo.get_by!([user_id: user_id, subscription_id: subscription_id])
    |> Repo.preload(:subscription)

    assign_subscription(socket, user_subscription_link.subscription)
  end

  def assign_updated_subscription(%{assigns: %{editing_record: editing_record, new_record: new_record, table_id: table_id}} = socket, subscription) do
    case is_expired?(subscription) do
      true -> push_redirect(socket, to: "/registration/edit")
      false ->
        case deer_table_from_subscription(subscription, table_id) do
          nil -> push_redirect(socket, to: "/dashboard")
          %{name: table_name} ->
            socket
            |> assign(:table_name, table_name)
            |> assign_subscription(subscription)
            |> maybe_assign_record_changeset(:new_record, subscription, new_record)
            |> maybe_assign_record_changeset(:editing_record, subscription, editing_record)
       end
     end
  end

  def assign_subscription(socket, subscription) do
    assign(socket,
      current_subscription: subscription,
      current_subscription_name: subscription.name,
      current_subscription_tables: subscription.deer_tables,
      current_subscription_deer_records_per_table_limit: subscription.deer_records_per_table_limit,
      storage_limit_kilobytes: subscription.storage_limit_kilobytes
    )
  end

  defp maybe_assign_record_changeset(socket, _assign_key, _subscription, nil), do: socket
  defp maybe_assign_record_changeset(socket, assign_key, subscription, %{data: %{deer_table_id: table_id}} = record) do
    assign(socket, assign_key, change_record(subscription, record, %{deer_table_id: table_id}))
  end
end
