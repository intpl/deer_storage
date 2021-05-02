defmodule DeerStorage.DeerRecords.DeerFile do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  embedded_schema do
    field :original_filename, :string
    field :kilobytes, :integer
    field :uploaded_by_user_id, :id
    field :mimetype, :string

    timestamps(updated_at: false)
  end

  @doc false
  def changeset(deer_file, attrs) do
    deer_file
    |> cast(attrs, [:id, :kilobytes, :original_filename, :uploaded_by_user_id, :mimetype])
    |> validate_required([:id, :kilobytes, :original_filename, :uploaded_by_user_id, :mimetype])
  end
end
