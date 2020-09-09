defmodule Pjeski.Subscriptions.DeerTable do
  use Ecto.Schema
  import Ecto.Changeset

  alias Pjeski.Subscriptions.DeerColumn

  embedded_schema do
    field :name, :string
    embeds_many :deer_columns, DeerColumn, on_replace: :delete
  end

  @doc false
  def ensure_no_columns_are_missing_changeset(deer_table_changeset, attrs, [subscription: subscription]) do
    changeset = changeset(deer_table_changeset, attrs)
    id = changeset.data.id # this should not be fetch_field

    case Enum.find(subscription.deer_tables, fn dt -> id == dt.id end) do
      nil -> add_error(changeset, :deer_columns, "missing")
      table_before ->
        columns_ids_before = Enum.map(table_before.deer_columns, fn dc -> dc.id end)
        columns_ids_proposed = Enum.map(fetch_field!(changeset, :deer_columns), fn dc -> dc.id end)

        case columns_ids_before -- columns_ids_proposed do
          [] ->
            changeset
            |> validate_length(:deer_columns, max: subscription.deer_columns_per_table_limit)
          _ -> add_error(changeset, :deer_columns, "missing")
        end
    end
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [:name])
    |> validate_required(:name)
    |> validate_length(:name, min: 3)
    |> validate_length(:name, max: 50)
    |> cast_embed(:deer_columns)
  end

  def add_empty_column(changeset), do: changeset(changeset, %{deer_columns: deer_columns_attrs(changeset) ++ [%{name: ""}]})

  def move_column_to_index(changeset, current_index, new_index) do
    deer_columns = deer_columns_attrs(changeset)
    new_index = if new_index > (length(deer_columns) - 1), do: 0, else: new_index

    new_deer_columns = deer_columns
    |> List.delete_at(current_index)
    |> List.insert_at(new_index, Enum.at(deer_columns, current_index))

    changeset(changeset, %{deer_columns: new_deer_columns})
  end

  defp deer_columns_attrs(changeset), do: fetch_field!(changeset, :deer_columns) |> Enum.map(&Map.from_struct/1)
end
