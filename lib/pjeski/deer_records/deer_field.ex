defmodule Pjeski.DeerRecords.DeerField do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:deer_column_id, :binary_id, autogenerate: false}
  embedded_schema do
    # field :deer_column_id, :string
    field :content, :string
  end

  @doc false
  def changeset(deer_field, attrs) do
    deer_field
    |> cast(attrs, [:deer_column_id, :content])
  end
end
