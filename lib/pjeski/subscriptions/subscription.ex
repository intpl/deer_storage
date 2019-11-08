defmodule Pjeski.Subscriptions.Subscription do
  use Ecto.Schema
  import Ecto.Changeset

  alias Pjeski.Users.User

  schema "subscriptions" do
    field :email, :string
    field :name, :string
    field :expires_on, :date
    has_many :users, User

    timestamps()
  end

  @doc false
  def changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [:email, :name, :expires_on])
    |> validate_required([:email, :name, :expires_on])
  end
end
