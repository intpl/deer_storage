defmodule Pjeski.UserAnimalBreeds.AnimalBreed do
  use Ecto.Schema
  import Ecto.Changeset

  alias Pjeski.Subscriptions.Subscription
  alias Pjeski.UserAnimalKinds.AnimalKind
  alias Pjeski.Users.User

  schema "animal_breeds" do
    field :name, :string
    field :notes, :string

    belongs_to :subscription, Subscription
    belongs_to :last_changed_by_user, User

    belongs_to :animal_kind, AnimalKind

    timestamps()
  end

  @doc false
  def changeset(animal_breed, attrs) do
    animal_breed
    |> cast(attrs, [:name, :notes, :animal_kind_id])
    |> validate_required([:name, :animal_kind_id])
  end
end
