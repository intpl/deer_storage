defmodule PjeskiWeb.ClientController do
  use PjeskiWeb, :controller

  alias Pjeski.UserClients
  alias Pjeski.UserClients.Client

  def index(conn, params) do
    live_render(conn, PjeskiWeb.ClientLive.Index, session: %{"query" => params["query"]})
  end

  def new(conn, _params) do
    subscription_id = user(conn).subscription_id
    changeset = UserClients.change_client_for_subscription(%Client{subscription_id: subscription_id}, subscription_id)
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"client" => client_params}) do
    case UserClients.create_client_for_user(client_params, user(conn)) do
      {:ok, client} ->
        conn
        |> put_flash(:info, "Client created successfully.")
        |> redirect(to: Routes.client_path(conn, :show, client))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    client = UserClients.get_client_for_subscription!(id, user(conn).subscription_id)
    render(conn, "show.html", client: client)
  end

  def edit(conn, %{"id" => id}) do
    subscription_id = user(conn).subscription_id
    client = UserClients.get_client_for_subscription!(id, subscription_id)
    changeset = UserClients.change_client_for_subscription(client, subscription_id)

    render(conn, "edit.html", client: client, changeset: changeset)
  end

  def update(conn, %{"id" => id, "client" => client_params}) do
    client = UserClients.get_client_for_subscription!(id, user(conn).subscription_id)

    case UserClients.update_client_for_user(client, client_params, user(conn)) do
      {:ok, client} ->
        conn
        |> put_flash(:info, "Client updated successfully.")
        |> redirect(to: Routes.client_path(conn, :show, client))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", client: client, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    subscription_id = user(conn).subscription_id
    client = UserClients.get_client_for_subscription!(id, subscription_id)

    {:ok, _client} = UserClients.delete_client_for_subscription(client, subscription_id)

    conn
    |> put_flash(:info, "Client deleted successfully.")
    |> redirect(to: Routes.client_path(conn, :index))
  end

  defp user(conn) do
    Pow.Plug.current_user(conn)
  end
end
