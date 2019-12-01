defmodule Pjeski.UserClients.Client do
  use Ecto.Schema
  import Ecto.Changeset

  alias Pjeski.Users.User
  alias Pjeski.Subscriptions.Subscription

  schema "clients" do
    field :address, :string
    field :city, :string
    field :email, :string
    field :name, :string
    field :notes, :string
    field :phone, :string

    belongs_to :last_changed_by_user, User
    belongs_to :user, User
    belongs_to :subscription, Subscription

    timestamps()
  end

  @doc false
  def changeset(client, attrs \\ %{}) do
    client
    |> cast(attrs, [:name, :phone, :email, :city, :address, :notes])
    |> validate_required([:name])
  end
end
