defmodule Pjeski.UserAnimals.Animal do
  use Ecto.Schema
  import Ecto.Changeset

  alias Pjeski.Subscriptions.Subscription
  alias Pjeski.Users.User
  alias Pjeski.UserClients.Client
  alias Pjeski.UserAnimalKinds.AnimalKind
  alias Pjeski.UserAnimalBreeds.AnimalBreed

  schema "animals" do
    field :name, :string
    field :notes, :string
    field :birth_year, :date

    belongs_to :subscription, Subscription
    belongs_to :last_changed_by_user, User
    belongs_to :user, User
    belongs_to :client, Client
    belongs_to :animal_kind, AnimalKind
    belongs_to :animal_breed, AnimalBreed

    timestamps()
  end

  @doc false
  def changeset(animal, attrs) do
    animal
    |> cast(attrs, [:name, :notes, :birth_year])
    |> validate_required([:name])
  end
end
