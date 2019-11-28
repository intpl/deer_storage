defmodule PjeskiWeb.ClientLive.Index do
  use Phoenix.LiveView

  import Pjeski.UserClients, only: [search_clients_for_subscription: 3, list_clients_for_subscription: 2]
  import Pjeski.Users.UserSessionUtils, only: [user_from_live_session: 1]

  def render(assigns), do: PjeskiWeb.ClientView.render("index.html", assigns)

  def mount(%{"query" => query, "pjeski_auth" => token}, socket) do
    user = user_from_live_session(token)
    subscription_id = user.subscription_id

    user.locale
    |> Atom.to_string
    |> Gettext.put_locale

    {:ok, clients} = search_clients(subscription_id, query, 1)
    {:ok, assign(socket, clients: clients, query: query, token: token)}
  end

  def handle_event("filter", %{"query" => query}, %{assigns: %{token: token}} = socket) when byte_size(query) <= 50 do
    user = user_from_live_session(token)
    subscription_id = user.subscription_id

    {:ok, clients} = search_clients(subscription_id, query, 1)
    {:noreply, assign(socket, token: token, clients: clients)}
  end

  # TODO: limit search queries from 3 characters
  # TODO: limit search queries from all spaces
  defp search_clients(nil, _, _), do: {:error, "invalid subscription id"} # this will probably never happen, but let's keep this edge case just in case
  defp search_clients(id, nil, page), do: {:ok, list_clients_for_subscription(id, page)}
  defp search_clients(id, "", page), do: {:ok, list_clients_for_subscription(id, page)}
  defp search_clients(id, q, page), do: {:ok, search_clients_for_subscription(id, q, page)}
end
