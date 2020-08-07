defmodule Pjeski.Subscriptions.DeerTable do
  use Ecto.Schema
  import Ecto.Changeset

  alias Pjeski.Subscriptions.DeerColumn

  embedded_schema do
    field :name, :string
    embeds_many :deer_columns, DeerColumn, on_replace: :delete
  end

  @doc false
  def changeset(deer_table, attrs) do
    deer_table
    |> cast(attrs, [:name])
    |> validate_required(:name)
    |> validate_length(:name, min: 3)
    |> validate_length(:name, max: 50)
    |> cast_embed(:deer_columns)
  end

  def add_empty_column_to_changeset(changeset) do
    deer_columns = Ecto.Changeset.fetch_field!(changeset, :deer_columns) |> Enum.map(&Map.from_struct/1)

    changeset(changeset, %{deer_columns: deer_columns ++ [%{name: ""}]})
  end
end
