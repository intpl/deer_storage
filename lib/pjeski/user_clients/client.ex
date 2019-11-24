defmodule Pjeski.UserClients.Client do
  use Ecto.Schema
  import Ecto.Changeset

  schema "clients" do
    field :address, :string
    field :city, :string
    field :email, :string
    field :name, :string
    field :notes, :string
    field :phone, :string
    field :phone_code, :string

    timestamps()
  end

  @doc false
  def changeset(client, attrs) do
    client
    |> cast(attrs, [:name, :phone_code, :phone, :email, :city, :address, :notes])
    |> validate_required([:name, :phone_code, :phone, :email, :city, :address, :notes])
  end
end
