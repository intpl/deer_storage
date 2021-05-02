defmodule DeerStorageWeb.PageController do
  use DeerStorageWeb, :controller

  def index(conn, _params), do: render(conn, "index.html")
end
