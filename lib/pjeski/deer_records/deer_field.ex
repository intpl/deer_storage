defmodule Pjeski.DeerRecords.DeerField do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:deer_column_id, :binary_id, autogenerate: false}
  embedded_schema do
    field :content, :string
  end

  @doc false
  def changeset(deer_field, attrs, [deer_table_id: table_id, subscription: subscription]) do
    deer_field
    |> cast(attrs, [:deer_column_id, :content])
    |> validate_tables_and_columns_integrity(table_id, subscription)
    |> validate_length(:content, max: 100)
  end

  defp validate_tables_and_columns_integrity(changeset, table_id, subscription) do
    case Enum.find(subscription.deer_tables, fn table -> table.id == table_id end) do
      nil ->
        add_error(changeset, :deer_column_id, "empty")
      deer_table ->
        validate_inclusion(changeset, :deer_column_id, Enum.map(deer_table.deer_columns, &(&1.id)))
    end
  end
end
