defmodule DeerStorage.SharedRecords.SharedRecord do
  use Ecto.Schema
  import Ecto.Changeset

  alias DeerStorage.Users.User
  alias DeerStorage.Subscriptions.Subscription
  alias DeerStorage.DeerRecords.DeerRecord

  @primary_key {:id, :binary_id, read_after_writes: true}
  schema "shared_records" do
    belongs_to :created_by_user, User
    belongs_to :deer_record, DeerRecord
    belongs_to :subscription, Subscription
    field :expires_on, :utc_datetime
    field :is_editable, :boolean

    timestamps(updated_at: false)
  end

  @doc false
  def changeset(shared_record, attrs) do
    ninety_days_from_now =
      DateTime.truncate(DateTime.add(DateTime.utc_now(), 7_776_000, :second), :second)

    shared_record
    |> cast(attrs, [:deer_record_id, :subscription_id, :created_by_user_id, :is_editable])
    |> cast(%{expires_on: ninety_days_from_now}, [:expires_on])
    |> validate_required([:deer_record_id, :subscription_id, :created_by_user_id])
  end
end
