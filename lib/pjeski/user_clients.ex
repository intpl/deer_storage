defmodule Pjeski.UserClients do
  import Ecto.Query, warn: false
  alias Ecto.Changeset

  alias Pjeski.Repo

  alias Pjeski.UserClients.Client

  def search_clients_for_subscription(query_string, subscription_id) do
    Repo.all(compose_search_query(query_string, subscription_id))
  end

  def list_clients_for_subscription(subscription_id) do
    Repo.all(clients_for_subscription_query(subscription_id))
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

  # test: Pjeski.UserClients.search_clients_for_subscription("b a", 22)

  defp compose_search_query(string, subscription_id) do
    filters = string
    |> String.split # FIXME: add guard clause for length of array of strings
    |> Enum.map(&(build_search_map(&1)))

    from c in clients_for_subscription_query(subscription_id), where: ^recursive_dynamic_query(filters)
  end

  # extract this function into a module for next models to use
  defp recursive_dynamic_query([{key, value} | []]), do: dynamic(^dynamic_ilike(key, value))
  defp recursive_dynamic_query([arr | []]), do: dynamic(^recursive_dynamic_query(arr))

  defp recursive_dynamic_query([{key, value}|rest]) do
    dynamic(^dynamic_ilike(key, value) or ^recursive_dynamic_query(rest))
  end

  defp recursive_dynamic_query([first | rest]) do
    dynamic(^recursive_dynamic_query(first) and ^recursive_dynamic_query(rest))
  end

  defp build_search_map(string) do
    string = "%#{string}%"

    [
      name: string,
      email: string,
      city: string,
      phone: string,
    ]
  end

  defp dynamic_ilike(key, value) do
    dynamic([c], ilike(field(c, ^key), ^value))
  end

  defp clients_for_subscription_query(subscription_id) do
    from c in Client, where: c.subscription_id == ^subscription_id
  end
end
