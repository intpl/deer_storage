defmodule PjeskiWeb.ClientLive.Index do
  use Phoenix.LiveView
  alias PjeskiWeb.Router.Helpers, as: Routes
  import PjeskiWeb.Gettext

  use PjeskiWeb.LiveHelpers.RenewTokenHandler
  import Pjeski.Users.UserSessionUtils, only: [user_from_live_session: 1]
  import Pjeski.EctoHelpers, only: [reset_errors: 1]

  alias Pjeski.UserClients.Client

  import Pjeski.UserClients, only: [
    change_client: 1,
    change_client: 2,
    create_client_for_user: 2,
    delete_client_for_subscription: 2,
    get_client_for_subscription!: 2,
    list_clients_for_subscription_and_user: 3,
    list_clients_for_subscription_and_user: 4,
    per_page: 0,
    update_client_for_user: 3
  ]

  def render(assigns), do: PjeskiWeb.ClientView.render("index.html", assigns)

  def mount(%{"pjeski_auth" => token}, socket) do
    user = user_from_live_session(token)

    if connected?(socket), do: :timer.send_interval(1200000, self(), :renew_token) # 1200000ms = 20min

    user.locale |> Atom.to_string |> Gettext.put_locale

    {:ok, assign(socket,
        current_client: nil,
        editing_client: nil,
        new_client: nil,
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

  def handle_event("close_show", _, socket), do: {:noreply, socket |> assign(current_client: nil)}
  def handle_event("close_new", _, socket), do: {:noreply, socket |> assign(new_client: nil)}
  def handle_event("close_edit", _, socket), do: {:noreply, socket |> assign(editing_client: nil)}

  def handle_event("validate_edit", %{"client" => attrs}, %{assigns: %{editing_client: client}} = socket) do
    {_, client_or_changeset} = reset_errors(client) |> change_client(attrs) |> Ecto.Changeset.apply_action(:update)
    {:noreply, socket |> assign(editing_client: change_client(client_or_changeset))}
  end

  def handle_event("save_edit", %{"client" => attrs}, %{assigns: %{editing_client: %{data: %{id: client_id}}, token: token}} = socket) do
    user = user_from_live_session(token)
    client = find_client_in_database(client_id, user.subscription_id)

    {:ok, _} = update_client_for_user(client, attrs, user_from_live_session(token))

    # waiting for this to get resolved: https://github.com/phoenixframework/phoenix_live_view/issues/340
    redirect_to_index(socket |> put_flash(:info, gettext("Client updated successfully.")))
  end

  def handle_event("save_new", %{"client" => attrs}, %{assigns: %{token: token}} = socket) do
    user = user_from_live_session(token)
    case create_client_for_user(attrs, user) do
      {:ok, _} ->
        redirect_to_index(
          socket
          # waiting for this to get resolved: https://github.com/phoenixframework/phoenix_live_view/issues/340
          |> put_flash(:info, gettext("Client created successfully."))
          |> assign(new_client: nil, query: nil))

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(new_client: changeset)}
    end

  end

  def handle_event("show", %{"client_id" => client_id}, %{assigns: %{clients: clients, token: token}} = socket) do
    user = user_from_live_session(token)
    client = find_client_in_list_or_database(client_id, clients, user.subscription_id)

    {:noreply, socket |> assign(current_client: client)}
  end

  def handle_event("new", _, %{assigns: %{token: token}} = socket) do
    subscription_id = user_from_live_session(token).subscription_id

    {:noreply, socket |> assign(new_client: change_client(%Client{subscription_id: subscription_id}))}
  end

  def handle_event("edit", %{"client_id" => client_id}, %{assigns: %{clients: clients, token: token}} = socket) do
    user = user_from_live_session(token)
    client = find_client_in_list_or_database(client_id, clients, user.subscription_id)

    {:noreply, socket |> assign(editing_client: change_client(client))}
  end

  def handle_event("delete", %{"client_id" => client_id}, %{assigns: %{clients: clients, token: token}} = socket) do
    user = user_from_live_session(token)
    client = find_client_in_list_or_database(client_id, clients, user.subscription_id)
    {:ok, _} = delete_client_for_subscription(client, user.subscription_id)

    # waiting for this to get resolved: https://github.com/phoenixframework/phoenix_live_view/issues/340
    redirect_to_index(socket |> put_flash(:info, gettext("User deleted successfully.")))
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

  defp change_page(new_page, %{assigns: %{token: token, query: query}} = socket) do
    user = user_from_live_session(token)
    {:ok, clients} = search_clients(user.subscription_id, user.id, query, new_page)

    {:noreply, socket |> assign(clients: clients, page: new_page, count: length(clients))}
  end

  defp search_clients(nil, _, _, _), do: {:error, "invalid subscription id"} # this will probably never happen, but let's keep this edge case just in case
  defp search_clients(_, nil, _, _), do: {:error, "invalid user id"} # this will probably never happen, but let's keep this edge case just in case

  defp search_clients(sid, uid, nil, page), do: {:ok, list_clients_for_subscription_and_user(sid, uid, page)}
  defp search_clients(sid, uid, "", page), do: {:ok, list_clients_for_subscription_and_user(sid, uid, page)}
  defp search_clients(sid, uid, q, page), do: {:ok, list_clients_for_subscription_and_user(sid, uid, q, page)}

  defp find_client_in_database(id, subscription_id), do: get_client_for_subscription!(id, subscription_id)
  defp find_client_in_list_or_database(id, clients, subscription_id) do
    id = id |> String.to_integer

    Enum.find(clients, fn client -> client.id == id end) || find_client_in_database(id, subscription_id)
  end

  defp redirect_to_index(socket) do
    {:noreply,
     live_redirect(assign(socket,
           current_client: nil,
           editing_client: nil,
           page: 1
         ), to: Routes.live_path(socket, PjeskiWeb.ClientLive.Index, query: socket.assigns.query)
     )}
  end
end
