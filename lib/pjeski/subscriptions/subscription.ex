defmodule Pjeski.Subscriptions.Subscription do
  use Ecto.Schema
  import Ecto.Changeset

  alias Pjeski.Subscriptions.DeerTable
  alias Pjeski.Users.User

  alias Pjeski.UserAvailableSubscriptionLinks.UserAvailableSubscriptionLink

  schema "subscriptions" do
    field :admin_notes, :string
    field :name, :string
    field :expires_on, :date, default: Date.add(Date.utc_today, 14)
    field :deer_files_limit, :integer, default: 100
    field :storage_limit_kilobytes, :integer, default: 51_200 # 50 MB

    has_many :user_subscription_links, UserAvailableSubscriptionLink
    many_to_many :users, User, join_through: UserAvailableSubscriptionLink
    # has_many :current_users, User

    embeds_many :deer_tables, DeerTable, on_replace: :delete

    timestamps()
  end

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
    # |> unique_constraint(:name)
  end

  @doc false
  def admin_changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [:name, :expires_on, :admin_notes, :storage_limit_kilobytes, :deer_files_limit])
    |> validate_required([:name])
  end
end
