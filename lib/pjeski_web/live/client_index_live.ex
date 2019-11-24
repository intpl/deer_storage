defmodule PjeskiWeb.ClientIndexLive do
  use Phoenix.LiveView
  alias Pjeski.Users.UserSessionUtils
  alias Pjeski.UserClients

  def mount(session, socket) do
    user = UserSessionUtils.user_from_live_session(session)

    {:ok,
     assign(socket,
       clients: UserClients.list_clients
     )}
  end

  def render(assigns) do
    PjeskiWeb.ClientView.render("_live_index.html", assigns)
  end
end
