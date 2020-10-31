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

    field :connected_deer_records_ids, {:array, :integer}, default: []
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

  def remove_ids_from_connected_deer_records(deer_record, ids) when is_list(ids) do
    change(deer_record) |> force_change(:connected_deer_records_ids, deer_record.connected_deer_records_ids -- ids) # this doesn't work without "force"
  end

  def remove_id_from_connected_deer_records(deer_record, id) when is_integer(id) do
    change(deer_record) |> force_change(:connected_deer_records_ids, deer_record.connected_deer_records_ids -- [id]) # this doesn't work without "force"
  end

  def append_id_to_connected_deer_records(deer_record, id) when is_integer(id) do
    new_connected_deer_records_ids = Enum.uniq(deer_record.connected_deer_records_ids ++ [id])
    change(deer_record) |> force_change(:connected_deer_records_ids, new_connected_deer_records_ids)
  end

  def prepend_deer_file_to_changeset(deer_record, deer_file) do
    existing_deer_files = Enum.map(deer_record.deer_files, fn df -> Map.from_struct(df) end)

    deer_record
    |> change
    |> cast(%{deer_files: [deer_file | existing_deer_files]}, [])
    |> cast_embed(:deer_files)
  end

  def reject_file_from_changeset(deer_record, file_id) do
    new_deer_files = Enum.map(deer_record.deer_files, &Map.from_struct/1)
    |> Enum.reject(fn deer_file -> deer_file.id == file_id end)

    deer_record
    |> change
    |> cast(%{deer_files: new_deer_files}, [])
    |> cast_embed(:deer_files)
  end

  def deer_files_stats(deer_record) do
    Enum.reduce(deer_record.deer_files, {0, 0}, fn deer_file, {files, kilobytes} ->
      {files + 1, kilobytes + deer_file.kilobytes}
    end)
  end
end
