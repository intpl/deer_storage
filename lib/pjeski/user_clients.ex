defmodule Pjeski.UserClients do
  import Ecto.Query, warn: false
  alias Ecto.Changeset

  alias Pjeski.Repo

  alias Pjeski.UserClients.Client

  @per_page 30

  def search_clients_for_subscription(subscription_id, query_string, page) do
    Repo.all(from c in Client,
      where: ^dynamic([c], c.subscription_id == ^subscription_id and ^compose_search_query(query_string)),
      offset: ^offset(page),
      limit: @per_page
    )
  end

  def list_clients_for_subscription(subscription_id, page) do
    Repo.all(from c in Client, where: c.subscription_id == ^subscription_id, offset: ^offset(page), limit: @per_page)
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

  defp compose_search_query(string) do
    filters = string
    |> String.replace("*", "%")
    |> String.split # FIXME: add guard clause for length of array of strings
    |> Enum.uniq
    |> Enum.map(&(build_search_map(&1)))

    dynamic([c], ^recursive_dynamic_query(filters))
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

    Keyword.new [:name, :email, :city, :phone], fn key -> {key, string} end
  end

  defp dynamic_ilike(key, value) do
    dynamic([c], ilike(field(c, ^key), ^value))
  end

  defp offset(page) when page > 0, do: (page - 1) * @per_page
end
