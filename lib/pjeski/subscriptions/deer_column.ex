defmodule Pjeski.Subscriptions.DeerColumn do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :name, :string
  end

  @doc false
  def changeset(deer_column, attrs) do
    deer_column
    |> cast(attrs, [:name])
    |> validate_required(:name)
    |> validate_length(:name, min: 3)
    |> validate_length(:name, max: 50)
  end
end
