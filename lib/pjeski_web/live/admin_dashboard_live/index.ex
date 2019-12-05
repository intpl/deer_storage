defmodule PjeskiWeb.AdminDashboardLive.Index do
  use Phoenix.LiveView

  def mount(%{"pjeski_auth" => token}, socket) do
    #if connected?(socket), do: :timer.send_interval(30000, self(), :update)

    {:ok, assign(socket, token: token)}
  end

  def render(assigns) do
    ~L"""
    Admin Dashboard<br>
    """
  end
end
