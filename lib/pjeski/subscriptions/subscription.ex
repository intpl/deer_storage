defmodule Pjeski.Subscriptions.Subscription do
  use Ecto.Schema
  import Ecto.Changeset

  alias Pjeski.Users.User

  schema "subscriptions" do
    field :admin_notes, :string
    field :email, :string
    field :name, :string
    field :time_zone, :string, default: "Europe/Warsaw"
    field :expires_on, :date, default: Date.add(Date.utc_today, 14)
    has_many :users, User

    timestamps()
  end

  @doc false
  def changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [:email, :name, :time_zone])
    |> validate_required([:email, :name])
    |> validate_length(:name, min: 3)
    |> validate_length(:name, max: 100)
    |> validate_length(:email, min: 3)
    |> validate_length(:email, max: 100)
    |> validate_format(:email, ~r/\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i)
    |> validate_inclusion(:time_zone, Tzdata.zone_list)
    |> unique_constraint(:email)
  end

  @doc false
  def admin_changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [:email, :name, :expires_on, :admin_notes, :time_zone])
    |> validate_required([:email, :name])
    |> validate_inclusion(:time_zone, Tzdata.zone_list)
    |> unique_constraint(:email)
  end
end
