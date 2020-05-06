defmodule PjeskiWeb.DashboardLive.Index do
  use Phoenix.LiveView

  import Pjeski.Users.UserSessionUtils, only: [get_live_user: 2]

  def mount(_params, %{"pjeski_auth" => token, "current_subscription_id" => subscription_id} = session, socket) do
    #if connected?(socket), do: :timer.send_interval(30000, self(), :update)

    {:ok, assign(socket, token: token, current_user: get_live_user(socket, session))}
  end

  def render(assigns) do
    ~L"""
    Dashboard for <%= @current_user.name %><br>
    """
  end

  def handle_params(_, _, socket), do: {:noreply, socket}
end
