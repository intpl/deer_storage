defmodule Pjeski.DeerRecords.DeerFile do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :original_filename, :string
    field :md5sum, :string
    field :kilobytes, :integer
    field :subscription_id, :id
    field :uploaded_by_user_id, :id

    timestamps()
  end

  @doc false
  def changeset(deer_file, attrs) do
    deer_file
    |> cast(attrs, [:kilobytes, :original_filename, :subscription_id, :uploaded_by_user_id, :md5sum])
    |> validate_required([:kilobytes, :original_filename, :subscription_id, :uploaded_by_user_id, :md5sum])
  end
end
