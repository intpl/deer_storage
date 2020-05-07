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
  def changeset(deer_record, attrs) do
    deer_record
    |> cast(attrs, [:deer_table_id])
    |> validate_required([:deer_table_id])
    |> cast_embed(:deer_fields)
  end
end
