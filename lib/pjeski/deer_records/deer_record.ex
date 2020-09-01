defmodule Pjeski.DeerRecords.DeerRecord do
  use Ecto.Schema
  import Ecto.Changeset

  alias Pjeski.Subscriptions.Subscription
  alias Pjeski.Users.User

  alias Pjeski.DeerRecords.DeerField
  alias Pjeski.DeerRecords.DeerFile

  schema "deer_records" do
    belongs_to :subscription, Subscription
    belongs_to :created_by_user, User
    belongs_to :updated_by_user, User
    field :deer_table_id, :string

    embeds_many :deer_fields, DeerField, on_replace: :delete
    embeds_many :deer_files, DeerFile, on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(deer_record, attrs, %{id: subscription_id, deer_tables: deer_tables} = subscription) do
    deer_tables_ids = Enum.map(deer_tables, &(&1.id))

    deer_record
    |> cast(%{subscription_id: subscription_id}, [:subscription_id])
    |> cast(attrs, [:deer_table_id])
    |> validate_required([:deer_table_id])
    |> validate_inclusion(:deer_table_id, deer_tables_ids)
    |> cast_embed(:deer_fields, with: {DeerField, :changeset, [[deer_table_id: attrs.deer_table_id, subscription: subscription]]})
  end

  def prepend_deer_file_to_changeset(deer_record, deer_file) do
    existing_deer_files = Enum.map(deer_record.deer_files, fn df -> Map.from_struct(df) end)

    deer_record
    |> change
    |> cast(%{deer_files: [deer_file | existing_deer_files]}, [])
    |> cast_embed(:deer_files)
  end

  def deer_files_stats(deer_record) do
    Enum.reduce(deer_record.deer_files, {0, 0}, fn deer_file, {files, kilobytes} ->
      {files + 1, kilobytes + deer_file.kilobytes}
    end)
  end
end
