defmodule PjeskiWeb.ClientLive.Index do
  use Phoenix.LiveView

  import Pjeski.UserClients, only: [search_clients_for_subscription: 2, list_clients_for_subscription: 1]
  import Pjeski.Users.UserSessionUtils, only: [user_from_live_session: 1]

  def render(assigns), do: PjeskiWeb.ClientView.render("index.html", assigns)

  def mount(%{"query" => query, "pjeski_auth" => token}, socket) do
    {:ok, clients} = search_clients(subscription_id_from_token(token), query)
    {:ok, assign(socket, clients: clients, query: query, token: token)}
  end

  def handle_event("filter", %{"query" => query}, %{assigns: %{token: token}} = socket) when byte_size(query) <= 50 do
    {:ok, clients} = search_clients(subscription_id_from_token(token), query)
    {:noreply, assign(socket, token: token, clients: clients)}
  end

  defp subscription_id_from_token(token), do: user_from_live_session(token).subscription_id

  defp search_clients(nil, _), do: {:error, "invalid subscription id"} # this will probably never happen, but let's keep this edge case just in case
  defp search_clients(id, nil), do: {:ok, list_clients_for_subscription(id)}
  defp search_clients(id, ""), do: {:ok, list_clients_for_subscription(id)}
  defp search_clients(id, q), do: {:ok, search_clients_for_subscription(id, q)}
end
