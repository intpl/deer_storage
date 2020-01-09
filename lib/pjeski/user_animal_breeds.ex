defmodule Pjeski.UserAnimalBreeds do
  import Ecto.Query, warn: false

  alias Ecto.Changeset
  alias Pjeski.Repo
  alias Pjeski.UserAnimalBreeds.AnimalBreed

  alias Pjeski.UserAnimalKinds

  use Pjeski.DbHelpers.ComposeSearchQuery, [:name]

  defmacro per_page, do: 30

  def list_animal_breeds_for_animal_kind_and_subscription(ak_id, subscription_id, query_string, page) do
    compose_search_query(query_string)
    |> build_search_query(subscription_id, page)
    |> where([ab], ab.animal_kind_id == ^ak_id)
    |> Repo.all
    |> Repo.preload(:animal_kind)
  end

  def list_animal_breeds_for_animal_kind_and_subscription(ak_id, subscription_id, page) do
    build_search_query(true, subscription_id, page)
    |> where([ab], ab.animal_kind_id == ^ak_id)
    |> Repo.all
    |> Repo.preload(:animal_kind)
  end

  def list_animal_breeds_for_subscription(subscription_id, query_string, page) do
    compose_search_query(query_string)
    |> build_search_query(subscription_id, page)
    |> Repo.all
    |> Repo.preload(:animal_kind)
  end

  def list_animal_breeds_for_subscription(subscription_id, page) do
    build_search_query(true, subscription_id, page)
    |> Repo.all
    |> Repo.preload(:animal_kind)
  end

  def get_animal_breed_for_subscription!(id, subscription_id) do
    Repo.get_by!(AnimalBreed, id: id, subscription_id: subscription_id) |> Repo.preload(:animal_kind)
  end

  def create_animal_breed_for_subscription(attrs, subscription_id) do
    %AnimalBreed{}
    |> change_animal_breed(attrs)
    |> Changeset.cast(%{subscription_id: subscription_id}, [:subscription_id])
    |> maybe_validate_animal_kind_ownership
    |> Repo.insert()
  end

  def update_animal_breed_for_user(%AnimalBreed{subscription_id: subscription_id} = animal_breed, attrs, %{subscription_id: subscription_id}) do
    animal_breed
    |> change_animal_breed(attrs)
    |> maybe_validate_animal_kind_ownership
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

  def maybe_validate_animal_kind_ownership(changeset) do
    case Ecto.Changeset.get_change(changeset, :animal_kind_id) do
      nil -> changeset
      animal_kind_id ->
        case changeset do
          %{action: nil} -> changeset
          %{action: _} ->
            UserAnimalKinds.get_animal_kind_for_subscription!(animal_kind_id, changeset.data.subscription_id) && changeset
        end
    end
  end

  defp offset(page) when page > 0, do: (page - 1) * per_page()
end
