defmodule PjeskiWeb.PageController do
  use PjeskiWeb, :controller

  def index(conn, _params), do: render(conn, "index.html")

  def not_found(conn, _params) do
    conn
      |> put_status(:not_found)
      |> render(PjeskiWeb.ErrorView, "404.html")
  end
end
