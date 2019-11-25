defmodule PjeskiWeb.ClientIndexLive do
  use Phoenix.LiveView

  alias Pjeski.Users.UserSessionUtils
  alias Pjeski.UserClients

  def mount(session, socket) do
    user = user_from_session_or_token(session)
    token = session["pjeski_auth"]

    {:ok,
     assign(socket,
       token: token,
       clients: list_clients_for_subscription(user.subscription_id)
     )}
  end

  def render(assigns) do
    PjeskiWeb.ClientView.render("_live_index.html", assigns)
  end

  def handle_event("reload", %{"token" => token}, socket) do
    subscription_id  = user_from_session_or_token(token).subscription_id

    {:noreply, assign(socket, clients: list_clients_for_subscription(subscription_id))}
  end

  defp list_clients_for_subscription(nil), do: [] # this will probably never happen, but let's keep this edge case just in case
  defp list_clients_for_subscription(subscription_id) do
    UserClients.list_clients_for_subscription(subscription_id)
  end

  defp user_from_session_or_token(%{"pjeski_auth" => token}), do: user_from_session_or_token(token)
  defp user_from_session_or_token(token) do
    UserSessionUtils.user_from_live_session(token)
  end
end
