defmodule PjeskiWeb.UserController do
  use PjeskiWeb, :controller
  import Plug.Conn, only: [assign: 3]

  def index(conn, _params) do
    subscription_id = Pow.Plug.current_user(conn).subscription_id

    conn
    |> assign(:users, Pjeski.Users.list_users_for_subscription_id(subscription_id))
    |> render("index.html")
  end
end
