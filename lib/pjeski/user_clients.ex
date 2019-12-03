defmodule Pjeski.UserClients do
  import Ecto.Query, warn: false

  alias Ecto.Changeset
  alias Pjeski.Repo
  alias Pjeski.UserClients.Client

  use Pjeski.DbHelpers.ComposeSearchQuery, [:name, :email, :city, :phone]

  defmacro per_page, do: 30

  def list_clients_for_subscription_and_user(subscription_id, user_id, query_string, page) do
    compose_search_query(query_string)
    |> build_search_query(subscription_id, user_id, page)
    |> Repo.all
  end

  def list_clients_for_subscription_and_user(subscription_id, user_id, page) do
    build_search_query(true, subscription_id, user_id, page)
    |> Repo.all
  end

  def get_client_for_subscription!(id, subscription_id), do: Repo.get_by!(Client, id: id, subscription_id: subscription_id)

  def create_client_for_user(attrs, user) do
    user_data = %{user_id: user.id, subscription_id: user.subscription_id}

    %Client{}
    |> Client.changeset(attrs)
    |> Changeset.cast(user_data, [:user_id, :subscription_id])
    |> Repo.insert()
  end

  def update_client_for_user(%Client{subscription_id: subscription_id} = client, attrs, %{subscription_id: subscription_id} = user) do
    user_data = %{last_changed_by_user_id: user.id}

    client
    |> Client.changeset(attrs)
    |> Changeset.cast(user_data, [:last_changed_by_user_id])
    |> Repo.update()
  end

  def delete_client_for_subscription(%Client{subscription_id: subscription_id} = client, subscription_id) do
    Repo.delete(client)
  end

  def change_client(client, attrs \\ %{}) do
    Client.changeset(client, attrs)
  end

  defp build_search_query(composed_query, subscription_id, user_id, page) do
    from c in Client,
      where: ^dynamic([c], c.subscription_id == ^subscription_id and ^composed_query),
      offset: ^offset(page),
      order_by: [desc: c.user_id == ^user_id],
      order_by: [desc: c.updated_at],
      limit: ^per_page()
  end

  defp offset(page) when page > 0, do: (page - 1) * per_page()
end
