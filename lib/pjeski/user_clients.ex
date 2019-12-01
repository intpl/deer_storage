defmodule Pjeski.UserClients do
  import Ecto.Query, warn: false

  alias Ecto.Changeset
  alias Pjeski.Repo
  alias Pjeski.UserClients.Client

  use Pjeski.DbHelpers.SearchQuery, [:name, :email, :city, :phone]

  @per_page 30

  def search_clients_for_subscription(subscription_id, user_id, query_string, page) do
    Repo.all(from c in Client,
      where: ^dynamic([c], c.subscription_id == ^subscription_id and ^compose_search_query(query_string)),
      offset: ^offset(page),
      order_by: [desc: c.user_id == ^user_id],
      order_by: [desc: c.id],
      limit: @per_page
    )
  end

  def list_clients_for_subscription(subscription_id, user_id, page) do
    Repo.all(from c in Client,
      where: c.subscription_id == ^subscription_id,
      offset: ^offset(page),
      order_by: [desc: c.user_id == ^user_id],
      order_by: [desc: c.id],
      limit: @per_page
    )
  end

  def get_client_for_subscription!(id, subscription_id), do: Repo.get_by!(Client, id: id, subscription_id: subscription_id)

  def create_client_for_user(attrs \\ %{}, user) do
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

  def change_client_for_subscription(%Client{subscription_id: subscription_id} = client, subscription_id) do
    Client.changeset(client, %{})
  end

  defp offset(page) when page > 0, do: (page - 1) * @per_page
end
