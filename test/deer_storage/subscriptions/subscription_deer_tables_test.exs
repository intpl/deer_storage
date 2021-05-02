defmodule DeerStorage.SubscriptionDeerTablesTest do
  use DeerStorage.DataCase
  import DeerStorage.DeerFixtures
  import DeerStorage.Subscriptions, only: [update_deer_table!: 3]
  import DeerStorage.Subscriptions.Helpers, only: [deer_tables_to_attrs: 1]

  describe "Helpers/deer_tables_to_attrs/1" do
    test "changes structs into maps of attrs" do
      subscription = create_valid_subscription_with_tables(2, 2)

      result = deer_tables_to_attrs(subscription.deer_tables)

      assert length(result) == 2
      assert length(List.first(result).deer_columns) == 2
      assert length(List.last(result).deer_columns) == 2
    end
  end

  describe "update_deer_table!/3" do
    setup do
      subscription = create_valid_subscription_with_tables(2, 2)
      target_table = List.first(subscription.deer_tables)

      {:ok,
       subscription: subscription,
       target_table: target_table,
       target_column: List.first(target_table.deer_columns),
       second_column_map: Map.from_struct(List.last(target_table.deer_columns))
      }
    end

    test "change order of columns", %{subscription: subscription, target_table: target_table, target_column: target_column, second_column_map: second_column_map} do
      {:ok, %{deer_tables: updated_deer_tables} = updated_subscription} = update_deer_table!(
        subscription,
        target_table.id,
        %{
          id: target_table.id,
          name: "new table name",
          deer_columns: [second_column_map, Map.from_struct(target_column)]
        }
      )

      assert subscription != updated_subscription
      updated_table = Enum.find(updated_deer_tables, fn table -> table.id == target_table.id end)

      assert Enum.at(updated_table.deer_columns, 0).id == second_column_map.id
      assert Enum.at(updated_table.deer_columns, 1).id == target_column.id
    end

    test "change name of one column leaving rest untouched", %{subscription: subscription, target_table: target_table, target_column: target_column, second_column_map: second_column_map} do
      {:ok, updated_subscription} = update_deer_table!(
        subscription,
        target_table.id,
        %{
          id: target_table.id,
          name: "new table name",
          deer_columns: [%{id: target_column.id, name: "new column name"}, second_column_map]
        }
      )

      assert subscription != updated_subscription

      updated_target_table = List.first(updated_subscription.deer_tables)
      updated_target_column = List.first(updated_target_table.deer_columns)

      assert updated_target_table.name == "new table name"
      assert updated_target_column.name == "new column name"
      assert updated_target_column.id == target_column.id

      assert List.last(updated_target_table.deer_columns) == List.last(List.first(subscription.deer_tables).deer_columns)
      assert List.last(updated_subscription.deer_tables) == List.last(subscription.deer_tables)
    end

    test "validates minimal length of deer column", %{subscription: subscription, target_table: target_table, target_column: target_column, second_column_map: second_column_map} do
      result = update_deer_table!(
        subscription,
        target_table.id,
        %{
          id: target_table.id,
          name: "new table name",
          deer_columns: [%{id: target_column.id, name: "x"}, second_column_map]
        }
      )

      assert {:error, _} = result
    end

    test "validates maximum length of deer column", %{subscription: subscription, target_table: target_table, target_column: target_column, second_column_map: second_column_map} do
      result = update_deer_table!(
        subscription,
        target_table.id,
        %{
          id: target_table.id,
          name: "new table name",
          deer_columns: [%{id: target_column.id, name: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1"}, second_column_map]
        }
      )

      assert {:error, _} = result
    end

    test "does not change params table id when invalid", %{subscription: subscription, target_table: target_table, target_column: target_column, second_column_map: second_column_map} do
      {:ok, updated_subscription} = update_deer_table!(subscription, "hacked", %{id: target_table.id, deer_columns: [%{id: target_column.id, name: "new value"}, second_column_map]})
      assert subscription == updated_subscription
    end

    test "does not change attrs table id when invalid", %{subscription: subscription, target_table: target_table, target_column: target_column, second_column_map: second_column_map} do
      assert {:error, _} = update_deer_table!(subscription, target_table.id, %{id: "hacked", deer_columns: [%{id: target_column.id, name: "new value"}, second_column_map]})
    end

    test "does not change column id when invalid", %{subscription: subscription, target_table: target_table, second_column_map: second_column_map} do
      assert {:error, _} = update_deer_table!(subscription, target_table.id, %{id: target_table.id, deer_columns: [%{id: "hacked id", name: "hacked name"}, second_column_map]})
    end
  end
end
