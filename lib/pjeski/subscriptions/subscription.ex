defmodule Pjeski.Subscriptions.Subscription do
  use Ecto.Schema
  import Ecto.Changeset
  import Pjeski.Subscriptions.Helpers

  alias Pjeski.Subscriptions.DeerTable
  alias Pjeski.Users.User

  alias Pjeski.UserAvailableSubscriptionLinks.UserAvailableSubscriptionLink

  schema "subscriptions" do
    field :admin_notes, :string
    field :name, :string
    field :expires_on, :date
    field :deer_files_limit, :integer, default: 100
    field :storage_limit_kilobytes, :integer, default: 51_200 # 50 MB
    field :deer_records_per_table_limit, :integer, default: 100
    field :deer_columns_per_table_limit, :integer, default: 10
    field :deer_tables_limit, :integer, default: 5

    has_many :user_subscription_links, UserAvailableSubscriptionLink
    many_to_many :users, User, join_through: UserAvailableSubscriptionLink
    # has_many :current_users, User

    embeds_many :deer_tables, DeerTable, on_replace: :delete

    timestamps()
  end

  # NOTE deer tables limit check happens in append_table/3
  @doc false
  def deer_changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [])
    |> cast_embed(:deer_tables)
  end

  @doc false
  def changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 3)
    |> validate_length(:name, max: 100)
    |> maybe_add_expires_on_date
  end

  @doc false
  def admin_changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [:name,
                   :expires_on,
                   :admin_notes,
                   :storage_limit_kilobytes,
                   :deer_files_limit,
                   :deer_tables_limit,
                   :deer_records_per_table_limit,
                   :deer_columns_per_table_limit])
    |> validate_required([:name])
  end

  def append_table(subscription, table_name, table_columns) do
    new_table_attrs = [%{name: table_name, deer_columns: Enum.map(table_columns, fn col_name -> %{name: col_name} end)}]
    deer_tables = deer_tables_to_attrs(fetch_field!(subscription, :deer_tables)) ++ new_table_attrs

    change(subscription)
    |> cast(%{deer_tables: deer_tables}, [])
    |> cast_embed(:deer_tables)
    |> validate_length(:deer_tables, max: subscription.data.deer_tables_limit)
  end

  defp maybe_add_expires_on_date(%{data: %{expires_on: nil}} = changeset) do
    put_change(changeset, :expires_on, Date.add(Date.utc_today, 90))
  end

  defp maybe_add_expires_on_date(changeset), do: changeset
end
