defmodule PjeskiWeb.ClientLive.Index do
  use Phoenix.LiveView
  alias PjeskiWeb.Router.Helpers, as: Routes

  alias Pjeski.UserClients.Client

  import Pjeski.Users.UserSessionUtils, only: [user_from_live_session: 1]
  import Pjeski.UserClients, only: [
    change_client_for_subscription: 2,
    list_clients: 3,
    list_clients: 4,
    per_page: 0,
    update_client_for_user: 3,
    get_client_for_subscription!: 2
  ]

  def render(assigns), do: PjeskiWeb.ClientView.render("index.html", assigns)

  def mount(%{"pjeski_auth" => token}, socket) do
    user = user_from_live_session(token)

    user.locale |> Atom.to_string |> Gettext.put_locale

    {:ok, assign(socket,
        current_client: nil,
        editing_client: nil,
        page: 1,
        per_page: per_page(),
        token: token,
        user_id: user.id
      )}
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

  def handle_info({:validate_edit_modal, attrs, _}, %{assigns: %{editing_client: client, token: token}} = socket) do
    subscription_id = user_from_live_session(token).subscription_id
    changeset = Client.changeset(client, attrs)

    {:noreply, socket |> assign(:editing_client, change_client_for_subscription(changeset, subscription_id))}
  end

  def handle_info({:save_edit_modal, attrs, _}, %{assigns: %{editing_client: changeset, token: token}} = socket) do
    {:ok, _} = update_client_for_user(changeset,  attrs, user_from_live_session(token))

    {:noreply,
     live_redirect(assign(socket,
           editing_client: nil,
           page: 1,
           current_client: nil
         ), to: Routes.live_path(socket, PjeskiWeb.ClientLive.Index))}
  end

  def handle_info(:close_edit_modal, socket), do: {:noreply, socket |> assign(editing_client: nil)}

  def handle_event("close_show", _, socket), do: {:noreply, socket |> assign(current_client: nil)}
  def handle_event("show", %{"client_id" => client_id}, %{assigns: %{clients: clients, token: token}} = socket) do
    user = user_from_live_session(token)
    client = find_client_in_list_or_database(client_id, clients, user.subscription_id)

    {:noreply, socket |> assign(current_client: client)}
  end

  def handle_event("edit", %{"client_id" => client_id}, %{assigns: %{clients: clients, token: token}} = socket) do
    user = user_from_live_session(token)
    client = find_client_in_list_or_database(client_id, clients, user.subscription_id)
    changeset = change_client_for_subscription(client, user.subscription_id) |> Map.put(:action, :update)

    {:noreply, socket |> assign(editing_client: changeset)}
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

  defp search_clients(nil, _, _, _), do: {:error, "invalid subscription id"} # this will probably never happen, but let's keep this edge case just in case
  defp search_clients(_, nil, _, _), do: {:error, "invalid user id"} # this will probably never happen, but let's keep this edge case just in case

  defp search_clients(sid, uid, nil, page), do: {:ok, list_clients(sid, uid, page)}
  defp search_clients(sid, uid, "", page), do: {:ok, list_clients(sid, uid, page)}
  defp search_clients(sid, uid, q, page), do: {:ok, list_clients(sid, uid, q, page)}

  defp find_client_in_list_or_database(id, clients, subscription_id) do
    id = id |> String.to_integer

    Enum.find(clients, fn client -> client.id == id end) || get_client_for_subscription!(id, subscription_id)
  end
end
