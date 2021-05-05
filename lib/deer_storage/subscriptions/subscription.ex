defmodule DeerStorage.Subscriptions.Subscription do
  use Ecto.Schema
  import Ecto.Changeset
  import DeerStorage.Subscriptions.Helpers

  alias DeerStorage.Subscriptions.DeerTable
  alias DeerStorage.Users.User

  alias DeerStorage.UserAvailableSubscriptionLinks.UserAvailableSubscriptionLink

  schema "subscriptions" do
    default_records_per_table_limit = System.get_env("NEW_SUBSCRIPTION_RECORDS_PER_TABLE_LIMIT") |> String.to_integer
    default_files_limit = System.get_env("NEW_SUBSCRIPTION_FILES_COUNT_LIMIT") |> String.to_integer
    default_storage_limit = System.get_env("NEW_SUBSCRIPTION_STORAGE_LIMIT_IN_KILOBYTES") |> String.to_integer
    default_columns_per_table_limit = System.get_env("NEW_SUBSCRIPTION_COLUMNS_PER_TABLE_LIMIT") |> String.to_integer
    default_tables_limit = System.get_env("NEW_SUBSCRIPTION_TABLES_LIMIT") |> String.to_integer

    field :admin_notes, :string
    field :name, :string
    field :expires_on, :date
    field :deer_records_per_table_limit, :integer, default: default_records_per_table_limit
    field :deer_files_limit, :integer, default: default_files_limit
    field :storage_limit_kilobytes, :integer, default: default_storage_limit
    field :deer_columns_per_table_limit, :integer, default: default_columns_per_table_limit
    field :deer_tables_limit, :integer, default: default_tables_limit

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
    |> validate_deer_columns_limit(subscription.data)
  end

  defp validate_deer_columns_limit(changeset, %{deer_columns_per_table_limit: limit}) do
    validate_change(changeset, :deer_tables, fn :deer_tables, changesets_list ->
      case Enum.all?(changesets_list, fn ch -> columns_length_valid?(fetch_field!(ch, :deer_columns), limit) end) do
        true -> []
        false -> [{:deer_tables, "deer columns limit exceeded"}]
      end
    end)
  end

  defp columns_length_valid?(list, limit) when length(list) > limit, do: false
  defp columns_length_valid?(_, _), do: true

  defp maybe_add_expires_on_date(%{data: %{expires_on: nil}} = changeset) do
    put_change(changeset, :expires_on, Date.add(Date.utc_today, 90))
  end

  defp maybe_add_expires_on_date(changeset), do: changeset
end
