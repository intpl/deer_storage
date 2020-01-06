defmodule PjeskiWeb.PageController do
  use PjeskiWeb, :controller

  def index(conn, _params) do
    render(
      conn,
      "index.html",
      navigation_template_when_logged_in: "navigation_outside_app.html",
      navigation_template_when_logged_out: "navigation_guest.html"
    )
  end
end
