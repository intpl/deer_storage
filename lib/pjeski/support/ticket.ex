defmodule Pjeski.Support.Ticket do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tickets" do
    field :title, :string
    field :user_id, :id

    timestamps()
  end

  @doc false
  def changeset(ticket, attrs) do
    ticket
    |> cast(attrs, [:title, :user_id])
    |> validate_required([:title, :user_id])
  end
end
