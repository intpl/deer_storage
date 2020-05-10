defmodule Pjeski.DeerRecords.DeerRecord do
  use Ecto.Schema
  import Ecto.Changeset

  alias Pjeski.Subscriptions.Subscription
  alias Pjeski.Users.User

  alias Pjeski.DeerRecords.DeerField

  schema "deer_records" do
    belongs_to :subscription, Subscription
    belongs_to :created_by_user, User
    belongs_to :updated_by_user, User
    field :deer_table_id, :string

    embeds_many :deer_fields, DeerField, on_replace: :delete

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
end
