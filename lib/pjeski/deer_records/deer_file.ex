defmodule Pjeski.DeerRecords.DeerFile do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  embedded_schema do
    field :original_filename, :string
    field :kilobytes, :integer
    field :subscription_id, :id
    field :uploaded_by_user_id, :id

    timestamps(updated_at: false)
  end

  @doc false
  def changeset(deer_file, attrs) do
    deer_file
    |> cast(attrs, [:id, :kilobytes, :original_filename, :subscription_id, :uploaded_by_user_id])
    |> validate_required([:id, :kilobytes, :original_filename, :subscription_id, :uploaded_by_user_id])
  end
end
