defmodule PjeskiWeb.Admin.SubscriptionView do
  alias PjeskiWeb.Router.Helpers, as: Routes
  use PjeskiWeb, :view

  def subscription_expires_datetime(_, %Pjeski.Users.User{subscription: nil}) do
    gettext("empty")
  end

  def subscription_expires_datetime(conn, %Pjeski.Users.User{subscription: subscription} = user) do
    link subscription.expires_on, to: Routes.admin_subscription_path(conn, :show, subscription.id)
  end

  def all_subscriptions_options do
    Pjeski.Subscriptions.list_subscriptions()
      |> Enum.map(fn subscription -> ["#{subscription.name} (#{subscription.email})", subscription.id]  end)
      |> Map.new(fn [k, v] -> {k, v} end)
  end
end
