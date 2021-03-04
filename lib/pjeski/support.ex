defmodule Pjeski.Support do
  import Ecto.Query, warn: false
  alias Pjeski.Repo

  alias Pjeski.Support.Ticket

  def list_tickets do
    Repo.all(Ticket)
  end

  def get_ticket!(id), do: Repo.get!(Ticket, id)

  def create_ticket(attrs \\ %{}) do
    %Ticket{}
    |> Ticket.changeset(attrs)
    |> Repo.insert()
  end

  def update_ticket(%Ticket{} = ticket, attrs) do
    ticket
    |> Ticket.changeset(attrs)
    |> Repo.update()
  end

  def delete_ticket(%Ticket{} = ticket) do
    Repo.delete(ticket)
  end

  def change_ticket(%Ticket{} = ticket, attrs \\ %{}) do
    Ticket.changeset(ticket, attrs)
  end

  alias Pjeski.Support.TicketMessage

  def list_ticket_messages do
    Repo.all(TicketMessage)
  end

  def get_ticket_message!(id), do: Repo.get!(TicketMessage, id)

  def create_ticket_message(attrs \\ %{}) do
    %TicketMessage{} |> TicketMessage.changeset(attrs) |> Repo.insert()
  end

  def update_ticket_message(%TicketMessage{} = ticket_message, attrs) do
    ticket_message |> TicketMessage.changeset(attrs) |> Repo.update()
  end

  def delete_ticket_message(%TicketMessage{} = ticket_message) do
    Repo.delete(ticket_message)
  end

  def change_ticket_message(%TicketMessage{} = ticket_message, attrs \\ %{}) do
    TicketMessage.changeset(ticket_message, attrs)
  end
end
