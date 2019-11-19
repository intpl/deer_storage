defmodule PjeskiWeb.Admin.SubscriptionView do
  alias PjeskiWeb.Router.Helpers, as: Routes
  use PjeskiWeb, :view

  def all_subscriptions_options_with_empty, do: Map.merge %{nil => nil}, all_subscriptions_options()

  def all_subscriptions_options do
    Pjeski.Subscriptions.list_subscriptions()
      |> Enum.map(fn subscription -> ["#{subscription.name} (#{subscription.email})", subscription.id]  end)
      |> Map.new(fn [k, v] -> {k, v} end)
  end
end
