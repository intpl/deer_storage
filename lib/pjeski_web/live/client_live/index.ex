defmodule PjeskiWeb.ClientLive.Index do
  use Phoenix.LiveView

  alias PjeskiWeb.Router.Helpers, as: Routes

  import Pjeski.UserClients, only: [search_clients_for_subscription: 4, list_clients_for_subscription: 3]
  import Pjeski.Users.UserSessionUtils, only: [user_from_live_session: 1]

  def render(assigns), do: PjeskiWeb.ClientView.render("index.html", assigns)

  def mount(%{"pjeski_auth" => token}, socket) do
    user = user_from_live_session(token)

    user.locale |> Atom.to_string |> Gettext.put_locale

    {:ok, assign(socket, token: token, page: 1, user_id: user.id)}
  end

  def handle_params(params, _, %{assigns: %{token: token}} = socket) do
    query = params["query"]

    case connected?(socket) do
      true ->
        user = user_from_live_session(token)
        {:ok, clients} = search_clients(user.subscription_id, user.id, query, 1)

        {:noreply, socket |> assign(clients: clients, query: query, count: length(clients))}
      false -> {:noreply, socket |> assign(query: query, clients: [], count: 0)}
    end
  end

  def handle_event("clear", _, socket) do
    {:noreply, live_redirect(socket |> assign(page: 1), to: Routes.live_path(socket, PjeskiWeb.ClientLive.Index))}
  end

  def handle_event("filter", %{"query" => query}, %{assigns: %{token: token}} = socket) when byte_size(query) <= 50 do
    user = user_from_live_session(token)
    {:ok, clients} = search_clients(user.subscription_id, user.id, query, 1)

    {:noreply, socket |> assign(clients: clients, query: query, page: 1, count: length(clients))}
  end

  def handle_event("next_page", _, %{assigns: %{page: page}} = socket), do: change_page(page + 1, socket)
  def handle_event("previous_page", _, %{assigns: %{page: page}} = socket), do: change_page(page - 1, socket)

  def change_page(new_page, %{assigns: %{token: token, query: query}} = socket) do
    user = user_from_live_session(token)
    {:ok, clients} = search_clients(user.subscription_id, user.id, query, new_page)

    {:noreply, socket |> assign(clients: clients, page: new_page, count: length(clients))}
  end

  # TODO: limit search queries from 3 characters
  # TODO: limit search queries from all spaces
  defp search_clients(nil, _, _), do: {:error, "invalid subscription id"} # this will probably never happen, but let's keep this edge case just in case
  defp search_clients(sid, uid, nil, page), do: {:ok, list_clients_for_subscription(sid, uid, page)}
  defp search_clients(sid, uid, "", page), do: {:ok, list_clients_for_subscription(sid, uid, page)}
  defp search_clients(sid, uid, q, page), do: {:ok, search_clients_for_subscription(sid, uid, q, page)}
end
