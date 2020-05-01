defmodule PjeskiWeb.UserController do
  use PjeskiWeb, :controller
  import Plug.Conn, only: [assign: 3]

  alias Pjeski.Users.UserSessionUtils

  def index(conn, _params) do
    subscription_id = UserSessionUtils.get_current_subscription_id_from_conn(conn)

    conn
    |> assign(:users, Pjeski.Users.list_users_for_subscription_id(subscription_id))
    |> render("index.html")
  end
end
