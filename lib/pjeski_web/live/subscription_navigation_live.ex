defmodule PjeskiWeb.SubscriptionNavigationLive do
  use Phoenix.LiveView

  def mount(:not_mounted_at_router, %{"subscription_id" => _subscription_id, "subscription_tables" => subscription_tables}, socket) do
    {:ok, assign(socket, subscription_tables: subscription_tables)}
  end

  def render(assigns) do
    ~L"""
      <%= for %{name: table_name, id: table_id} <- @subscription_tables do %>
        <a class="navbar-item" href="#<%= table_id %>">
          <%= table_name %>
        </a>
      <% end %>
    """
  end
end
