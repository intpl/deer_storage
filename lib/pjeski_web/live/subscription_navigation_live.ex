defmodule PjeskiWeb.SubscriptionNavigationLive do
  alias PjeskiWeb.Router.Helpers, as: Routes
  use Phoenix.LiveView

  def mount(:not_mounted_at_router, %{"subscription_id" => _subscription_id, "subscription_tables" => subscription_tables}, socket) do
    {:ok, assign(socket, subscription_tables: subscription_tables)}
  end

  def render(assigns) do
    ~L"""
      <%= for %{name: table_name, id: table_id} <- @subscription_tables do %>
        <%= live_redirect table_name, to: Routes.live_path(@socket, PjeskiWeb.DeerRecordsLive.Index, table_id       ), class: "navbar-item" %>
      <% end %>
    """
  end
end
