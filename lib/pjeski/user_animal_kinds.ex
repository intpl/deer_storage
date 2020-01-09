defmodule Pjeski.UserAnimalKinds do
  import Ecto.Query, warn: false

  alias Ecto.Changeset
  alias Pjeski.Repo
  alias Pjeski.UserAnimalKinds.AnimalKind

  use Pjeski.DbHelpers.ComposeSearchQuery, [:name]

  defmacro per_page, do: 30

  def list_animal_kinds_for_subscription(subscription_id, query_string, page) do
    compose_search_query(query_string)
    |> build_search_query(subscription_id, page)
    |> Repo.all
  end

  def list_animal_kinds_for_subscription(subscription_id, page) do
    build_search_query(true, subscription_id, page)
    |> Repo.all
  end

  def pluck_animal_kinds_structs_for_subscription(subscription_id) do
    query = from ak in AnimalKind,
      where: ak.subscription_id == ^subscription_id,
      limit: 1000,
      select: struct(ak, [:name, :id])

    Repo.all(query)
  end

  def get_animal_kind_for_subscription!(id, subscription_id), do: Repo.get_by!(AnimalKind, id: id, subscription_id: subscription_id)

  def create_animal_kind_for_subscription(attrs, subscription_id) do
    %AnimalKind{}
    |> change_animal_kind(attrs)
    |> Changeset.cast(%{subscription_id: subscription_id}, [:subscription_id])
    |> Repo.insert()
  end

  def update_animal_kind_for_user(%AnimalKind{subscription_id: subscription_id} = animal_kind, attrs, %{subscription_id: subscription_id}) do
    animal_kind
    |> change_animal_kind(attrs)
    |> Repo.update()
  end

  def delete_animal_kind_for_subscription(%AnimalKind{subscription_id: subscription_id} = animal_kind, subscription_id) do
    Repo.delete(animal_kind)
  end

  def change_animal_kind(animal_kind, attrs \\ %{}) do
    AnimalKind.changeset(animal_kind, attrs)
  end

  defp build_search_query(composed_query, subscription_id, page) do
    from ak in AnimalKind,
      where: ^dynamic([ak], ak.subscription_id == ^subscription_id and ^composed_query),
      offset: ^offset(page),
      order_by: [desc: ak.updated_at],
      limit: ^per_page()
  end

  defp offset(page) when page > 0, do: (page - 1) * per_page()
end
