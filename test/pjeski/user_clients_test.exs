defmodule Pjeski.UserClientsTest do
  use Pjeski.DataCase

  alias Pjeski.UserClients

  describe "clients" do
    alias Pjeski.UserClients.Client

    @valid_attrs %{address: "some address", city: "some city", email: "some email", name: "some name", notes: "some notes", phone: "some phone"}
    @update_attrs %{address: "some updated address", city: "some updated city", email: "some updated email", name: "some updated name", notes: "some updated notes", phone: "some updated phone"}
    @invalid_attrs %{address: nil, city: nil, email: nil, name: nil, notes: nil, phone: nil}

    def client_fixture(attrs \\ %{}) do
      {:ok, client} =
        attrs
        |> Enum.into(@valid_attrs)
        |> UserClients.create_client()

      client
    end

    test "list_clients/0 returns all clients" do
      client = client_fixture()
      assert UserClients.list_clients() == [client]
    end

    test "get_client!/1 returns the client with given id" do
      client = client_fixture()
      assert UserClients.get_client!(client.id) == client
    end

    test "create_client/1 with valid data creates a client" do
      assert {:ok, %Client{} = client} = UserClients.create_client(@valid_attrs)
      assert client.address == "some address"
      assert client.city == "some city"
      assert client.email == "some email"
      assert client.name == "some name"
      assert client.notes == "some notes"
      assert client.phone == "some phone"
    end

    test "create_client/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = UserClients.create_client(@invalid_attrs)
    end

    test "update_client/2 with valid data updates the client" do
      client = client_fixture()
      assert {:ok, %Client{} = client} = UserClients.update_client(client, @update_attrs)
      assert client.address == "some updated address"
      assert client.city == "some updated city"
      assert client.email == "some updated email"
      assert client.name == "some updated name"
      assert client.notes == "some updated notes"
      assert client.phone == "some updated phone"
    end

    test "update_client/2 with invalid data returns error changeset" do
      client = client_fixture()
      assert {:error, %Ecto.Changeset{}} = UserClients.update_client(client, @invalid_attrs)
      assert client == UserClients.get_client!(client.id)
    end

    test "delete_client/1 deletes the client" do
      client = client_fixture()
      assert {:ok, %Client{}} = UserClients.delete_client(client)
      assert_raise Ecto.NoResultsError, fn -> UserClients.get_client!(client.id) end
    end

    test "change_client/1 returns a client changeset" do
      client = client_fixture()
      assert %Ecto.Changeset{} = UserClients.change_client(client)
    end
  end
end
