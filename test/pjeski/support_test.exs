defmodule Pjeski.SupportTest do
  use Pjeski.DataCase

  alias Pjeski.Support

  describe "tickets" do
    alias Pjeski.Support.Ticket

    @valid_attrs %{title: "some title"}
    @update_attrs %{title: "some updated title"}
    @invalid_attrs %{title: nil}

    def ticket_fixture(attrs \\ %{}) do
      {:ok, ticket} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Support.create_ticket()

      ticket
    end

    test "list_tickets/0 returns all tickets" do
      ticket = ticket_fixture()
      assert Support.list_tickets() == [ticket]
    end

    test "get_ticket!/1 returns the ticket with given id" do
      ticket = ticket_fixture()
      assert Support.get_ticket!(ticket.id) == ticket
    end

    test "create_ticket/1 with valid data creates a ticket" do
      assert {:ok, %Ticket{} = ticket} = Support.create_ticket(@valid_attrs)
      assert ticket.title == "some title"
    end

    test "create_ticket/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Support.create_ticket(@invalid_attrs)
    end

    test "update_ticket/2 with valid data updates the ticket" do
      ticket = ticket_fixture()
      assert {:ok, %Ticket{} = ticket} = Support.update_ticket(ticket, @update_attrs)
      assert ticket.title == "some updated title"
    end

    test "update_ticket/2 with invalid data returns error changeset" do
      ticket = ticket_fixture()
      assert {:error, %Ecto.Changeset{}} = Support.update_ticket(ticket, @invalid_attrs)
      assert ticket == Support.get_ticket!(ticket.id)
    end

    test "delete_ticket/1 deletes the ticket" do
      ticket = ticket_fixture()
      assert {:ok, %Ticket{}} = Support.delete_ticket(ticket)
      assert_raise Ecto.NoResultsError, fn -> Support.get_ticket!(ticket.id) end
    end

    test "change_ticket/1 returns a ticket changeset" do
      ticket = ticket_fixture()
      assert %Ecto.Changeset{} = Support.change_ticket(ticket)
    end
  end

  describe "ticket_messages" do
    alias Pjeski.Support.TicketMessage

    @valid_attrs %{body: "some body"}
    @update_attrs %{body: "some updated body"}
    @invalid_attrs %{body: nil}

    def ticket_message_fixture(attrs \\ %{}) do
      {:ok, ticket_message} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Support.create_ticket_message()

      ticket_message
    end

    test "list_ticket_messages/0 returns all ticket_messages" do
      ticket_message = ticket_message_fixture()
      assert Support.list_ticket_messages() == [ticket_message]
    end

    test "get_ticket_message!/1 returns the ticket_message with given id" do
      ticket_message = ticket_message_fixture()
      assert Support.get_ticket_message!(ticket_message.id) == ticket_message
    end

    test "create_ticket_message/1 with valid data creates a ticket_message" do
      assert {:ok, %TicketMessage{} = ticket_message} = Support.create_ticket_message(@valid_attrs)
      assert ticket_message.body == "some body"
    end

    test "create_ticket_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Support.create_ticket_message(@invalid_attrs)
    end

    test "update_ticket_message/2 with valid data updates the ticket_message" do
      ticket_message = ticket_message_fixture()
      assert {:ok, %TicketMessage{} = ticket_message} = Support.update_ticket_message(ticket_message, @update_attrs)
      assert ticket_message.body == "some updated body"
    end

    test "update_ticket_message/2 with invalid data returns error changeset" do
      ticket_message = ticket_message_fixture()
      assert {:error, %Ecto.Changeset{}} = Support.update_ticket_message(ticket_message, @invalid_attrs)
      assert ticket_message == Support.get_ticket_message!(ticket_message.id)
    end

    test "delete_ticket_message/1 deletes the ticket_message" do
      ticket_message = ticket_message_fixture()
      assert {:ok, %TicketMessage{}} = Support.delete_ticket_message(ticket_message)
      assert_raise Ecto.NoResultsError, fn -> Support.get_ticket_message!(ticket_message.id) end
    end

    test "change_ticket_message/1 returns a ticket_message changeset" do
      ticket_message = ticket_message_fixture()
      assert %Ecto.Changeset{} = Support.change_ticket_message(ticket_message)
    end
  end
end
