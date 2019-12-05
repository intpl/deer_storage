defmodule Pjeski.UserAnimalKinds.AnimalKind do
  use Ecto.Schema
  import Ecto.Changeset

  alias Pjeski.Subscriptions.Subscription

  schema "animal_kinds" do
    field :name, :string
    field :notes, :string

    belongs_to :subscription, Subscription

    timestamps()
  end

  @doc false
  def changeset(animal_kind, attrs) do
    animal_kind
    |> cast(attrs, [:name, :notes])
    |> validate_required([:name])
  end
end
