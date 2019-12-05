defmodule Pjeski.UserAnimalBreeds do
  import Ecto.Query, warn: false

  alias Ecto.Changeset
  alias Pjeski.Repo
  alias Pjeski.UserAnimalBreeds.AnimalBreed

  use Pjeski.DbHelpers.ComposeSearchQuery, [:name]

  defmacro per_page, do: 30

  def list_animal_breeds_for_subscription(subscription_id, query_string, page) do
    compose_search_query(query_string)
    |> build_search_query(subscription_id, page)
    |> Repo.all
  end

  def list_animal_breeds_for_subscription(subscription_id, page) do
    build_search_query(true, subscription_id, page)
    |> Repo.all
  end

  def get_animal_breed_for_subscription!(id, subscription_id), do: Repo.get_by!(AnimalBreed, id: id, subscription_id: subscription_id)

  def create_animal_breed_for_subscription(attrs, subscription_id) do
    %AnimalBreed{}
    |> AnimalBreed.changeset(attrs)
    |> Changeset.cast(%{subscription_id: subscription_id}, [:subscription_id])
    |> Repo.insert()
  end

  def update_animal_breed_for_user(%AnimalBreed{subscription_id: subscription_id} = animal_breed, attrs, %{subscription_id: subscription_id} = user) do
    animal_breed
    |> AnimalBreed.changeset(attrs)
    |> Repo.update()
  end

  def delete_animal_breed_for_subscription(%AnimalBreed{subscription_id: subscription_id} = animal_breed, subscription_id) do
    Repo.delete(animal_breed)
  end

  def change_animal_breed(animal_breed, attrs \\ %{}) do
    AnimalBreed.changeset(animal_breed, attrs)
  end

  defp build_search_query(composed_query, subscription_id, page) do
    from ab in AnimalBreed,
      where: ^dynamic([ab], ab.subscription_id == ^subscription_id and ^composed_query),
      offset: ^offset(page),
      order_by: [desc: ab.updated_at],
      limit: ^per_page()
  end

  defp offset(page) when page > 0, do: (page - 1) * per_page()
end
