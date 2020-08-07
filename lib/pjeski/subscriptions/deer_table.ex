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

  def add_empty_column(changeset), do: changeset(changeset, %{deer_columns: deer_columns_attrs(changeset) ++ [%{name: ""}]})

  def move_column_to_index(changeset, current_index, new_index) do
    deer_columns = deer_columns_attrs(changeset)

    new_deer_columns = deer_columns
    |> List.delete_at(current_index)
    |> List.insert_at(new_index, Enum.at(deer_columns, current_index))

    changeset(changeset, %{deer_columns: new_deer_columns})
  end

  defp deer_columns_attrs(changeset), do: fetch_field!(changeset, :deer_columns) |> Enum.map(&Map.from_struct/1)
end
