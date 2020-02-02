defmodule Pjeski.UserAnimals do
  import Ecto.Query, warn: false

  alias Ecto.Changeset
  alias Pjeski.Repo
  alias Pjeski.UserAnimals.Animal

  use Pjeski.DbHelpers.ComposeSearchQuery, [:name]

  defmacro per_page, do: 30

  # TODO: remove preloads from all of the following methods
  def list_animals_for_animal_kind_and_subscription(ak_id, subscription_id, query_string, page) do
    compose_search_query(query_string)
    |> build_search_query(subscription_id, page)
    |> where([a], a.animal_kind_id == ^ak_id)
    |> Repo.all
    |> Repo.preload(:animal_kind)
  end

  def list_animals_for_animal_kind_and_subscription(ak_id, subscription_id, page) do
    build_search_query(true, subscription_id, page)
    |> where([a], a.animal_kind_id == ^ak_id)
    |> Repo.all
    |> Repo.preload(:animal_kind)
  end

  def list_animals_for_animal_kind_and_breed_and_subscription(ak_id, ab_id, subscription_id, query_string, page) do
    compose_search_query(query_string)
    |> build_search_query(subscription_id, page)
    |> where([a], a.animal_breed_id == ^ab_id)
    |> where([a], a.animal_kind_id == ^ak_id)
    |> Repo.all
    |> Repo.preload(:animal_kind)
  end

  def list_animals_for_animal_kind_and_breed_and_subscription(ak_id, ab_id, subscription_id, page) do
    build_search_query(true, subscription_id, page)
    |> where([a], a.animal_breed_id == ^ab_id)
    |> where([a], a.animal_kind_id == ^ak_id)
    |> Repo.all
    |> Repo.preload(:animal_kind)
  end

  def list_animals_for_subscription(subscription_id, query_string, page) do
    compose_search_query(query_string)
    |> build_search_query(subscription_id, page)
    |> Repo.all
    |> Repo.preload(:animal_kind)
  end

  def list_animals_for_subscription(subscription_id, page) do
    build_search_query(true, subscription_id, page)
    |> Repo.all
    |> Repo.preload(:animal_kind)
  end

  def get_animal_for_subscription!(id, subscription_id), do: Repo.get_by!(Animal, id: id, subscription_id: subscription_id)

  def create_animal_for_user(attrs, user) do
    user_data = %{user_id: user.id, subscription_id: user.subscription_id}

    %Animal{}
    |> Animal.changeset(attrs)
    |> Changeset.cast(user_data, [:subscription_id])
    |> Repo.insert()
  end

  def update_animal_for_user(%Animal{subscription_id: subscription_id} = animal, attrs, %{subscription_id: subscription_id} = user) do
    user_data = %{last_changed_by_user_id: user.id}

    animal
    |> Animal.changeset(attrs)
    |> Changeset.cast(user_data, [:last_changed_by_user_id])
    |> Repo.update()
  end

  def delete_animal_for_subscription(%Animal{subscription_id: subscription_id} = animal, subscription_id) do
    Repo.delete(animal)
  end

  def change_animal(animal, attrs \\ %{}) do
    Animal.changeset(animal, attrs)
  end

  defp build_search_query(composed_query, subscription_id, page) do
    from a in Animal,
      where: ^dynamic([a], a.subscription_id == ^subscription_id and ^composed_query),
      offset: ^offset(page),
      order_by: [desc: a.updated_at],
      limit: ^per_page()
  end

  defp offset(page) when page > 0, do: (page - 1) * per_page()
end
