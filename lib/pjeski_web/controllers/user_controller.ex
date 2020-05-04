defmodule PjeskiWeb.UserController do
  use PjeskiWeb, :controller
  import Plug.Conn, only: [assign: 3]

  import PjeskiWeb.ControllerHelpers.SubscriptionHelpers, only: [verify_if_subscription_is_expired: 2]

  plug :verify_if_subscription_is_expired

  def index(%{assigns: %{current_subscription: %{id: current_subscription_id}}} = conn, _params) do
    conn
    |> assign(:users, Pjeski.Users.list_users_for_subscription_id(current_subscription_id))
    |> render("index.html")
  end
end
