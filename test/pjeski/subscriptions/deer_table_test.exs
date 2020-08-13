defmodule Pjeski.Subscriptions.DeerTableTest do
  use Pjeski.DataCase
  import Pjeski.DeerFixtures
  import Ecto.Changeset, only: [fetch_field!: 2]

  alias Pjeski.Subscriptions.DeerTable
  import DeerTable, only: [changeset: 2, move_column_to_index: 3]

  describe "DeerTable.move_column_to_index/3" do
    setup do
      subscription = create_valid_subscription_with_tables(1, 10)
      attrs = %{name: "example table",
                deer_columns: [%{name: "first table"},
                               %{name: "second table"},
                               %{name: "third table"},
                               %{name: "fourth table"}]}

      changeset = changeset(%DeerTable{}, attrs)

      {:ok, subscription: subscription, table_changeset: changeset}
    end

    test "moves column to specific index: 1->2", %{table_changeset: table_changeset} do
      new_deer_columns = table_changeset
      |> move_column_to_index(1, 2)
      |> fetch_field!(:deer_columns)

      assert [%{id: nil, name: "first table"}, %{id: nil, name: "third table"}, %{id: nil, name: "second table"} | _] = new_deer_columns
    end

    test "moves column to specific index: 2->1", %{table_changeset: table_changeset} do
      new_deer_columns = table_changeset
      |> move_column_to_index(2, 1)
      |> fetch_field!(:deer_columns)

      assert [%{id: nil, name: "first table"}, %{id: nil, name: "third table"}, %{id: nil, name: "second table"} | _] = new_deer_columns
    end

    test "moves column to specific index: 0->-1", %{table_changeset: table_changeset} do
      new_deer_columns = table_changeset
      |> move_column_to_index(0, -1)
      |> fetch_field!(:deer_columns)

      assert [%{id: nil, name: "second table"}, %{id: nil, name: "third table"}, %{id: nil, name: "fourth table"}, %{id: nil, name: "first table"}] = new_deer_columns
    end

    test "moves column to specific index: 3->4", %{table_changeset: table_changeset} do
      new_deer_columns = table_changeset
      |> move_column_to_index(3, 4)
      |> fetch_field!(:deer_columns)

      assert [%{id: nil, name: "fourth table"}, %{id: nil, name: "first table"}, %{id: nil, name: "second table"}, %{id: nil, name: "third table"}] = new_deer_columns
    end
  end
end
