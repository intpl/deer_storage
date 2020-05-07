defmodule PjeskiWeb.DeerRecordsLive.Index do
  use Phoenix.LiveView

  import Pjeski.Users.UserSessionUtils, only: [get_live_user: 2]

  alias Pjeski.Repo
  alias Pjeski.Subscriptions.Subscription
  alias Pjeski.UserAvailableSubscriptionLinks.UserAvailableSubscriptionLink

  def mount(_params, %{"pjeski_auth" => token, "current_subscription_id" => current_subscription_id} = session, socket) do
    #if connected?(socket), do: :timer.send_interval(30000, self(), :update)
    user = get_live_user(socket, session)

    {:ok, assign(socket,
        token: token,
        current_user: user,
        current_subscription_id: current_subscription_id
      )}
  end

  def render(assigns) do
    ~L"""
    Records <%= @table_name %>
    """
  end

  def handle_params(%{"table_id" => table_id}, _, %{assigns: %{current_user: user, current_subscription_id: subscription_id}} = socket) do
    user_subscription_link = Repo.get_by!(UserAvailableSubscriptionLink, [user_id: user.id, subscription_id: subscription_id])
    |> Repo.preload(:subscription)
    subscription = user_subscription_link.subscription

    {:noreply, assign(socket,
       subscription: subscription,
       user_subscription_link: user_subscription_link,
       table_name: table_name_from_subscription(subscription, table_id)
      )}
  end

  defp table_name_from_subscription(%{deer_tables: deer_tables}, table_id) do
    %{name: name} = Enum.find(deer_tables, fn deer_table -> deer_table.id == table_id end)

    name
  end
end
