defmodule Pjeski.Support.TicketMessage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ticket_messages" do
    field :body, :string
    field :user_id, :id
    field :ticket_id, :id

    timestamps()
  end

  @doc false
  def changeset(ticket_message, attrs) do
    ticket_message
    |> cast(attrs, [:body, :user_id, :ticket_id])
    |> validate_required([:body, :user_id, :ticket_id])
  end
end
