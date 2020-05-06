defmodule PjeskiWeb.SubscriptionNavigationLive do
  use Phoenix.LiveView

  def mount(:not_mounted_at_router, %{"subscription_id" => subscription_id}, socket) do
    {:ok, assign(socket, subscription_id: subscription_id)}
  end

  def render(assigns) do
    ~L"""
      <a class="navbar-item">Fields</a>
      <a class="navbar-item">For</a>
      <a class="navbar-item">Subscription no <%= @subscription_id %></a>
    """
  end
end
