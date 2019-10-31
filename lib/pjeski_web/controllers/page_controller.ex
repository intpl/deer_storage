defmodule PjeskiWeb.PageController do
  use PjeskiWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
