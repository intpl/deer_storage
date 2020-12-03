defmodule Pjeski.CsvImporterTest do
  use Pjeski.DataCase
  import Pjeski.Fixtures

  alias Pjeski.CsvImporter
  alias Pjeski.Subscriptions
  alias Pjeski.DeerRecords.DeerRecord

  @polish_people_csv File.cwd! <> "/test/csv_examples/polish_people.csv"

  describe "run!" do
    setup do
      user = create_valid_user_with_subscription() |> Repo.preload(:last_used_subscription)

      start_supervised(DeerCache.RecordsCountsCache) # TODO

      all_records_for = fn (subscription_id) -> DeerRecord |> where([dr], dr.subscription_id == ^subscription_id) |> Pjeski.Repo.all end

      {:ok, user: user, subscription: user.last_used_subscription, all_records_for: all_records_for}
    end

    test "imports polish_people.csv correctly", %{subscription: subscription, user: user, all_records_for: all_records_for} do
      assert {:ok, :ok} = CsvImporter.run!(subscription, user, @polish_people_csv, "test.csv", "XYZ")

      records = all_records_for.(subscription.id)

      # all records have been created
      assert 3 = length(records)
      assert DeerCache.RecordsCountsCache.fetch_count(List.first(records).deer_table_id) == 3

      # subscription has new deer_table
      [table_id] = Enum.map(records, fn r -> r.deer_table_id end) |> Enum.uniq
      table = Pjeski.Subscriptions.get_subscription!(subscription.id).deer_tables |> Enum.find(fn dt -> dt.id == table_id end)

      # importer keeps in mind original filename
      assert table.name == "test.csv"

      # keeps user id in records
      assert [user.id] == Enum.map(records, fn r -> r.created_by_user_id end) |> Enum.uniq
      assert [user.id] == Enum.map(records, fn r -> r.updated_by_user_id end) |> Enum.uniq
    end

    test "returns error when deer_tables_limit is being exceeded", %{subscription: subscription, user: user, all_records_for: all_records_for} do
      {:ok, subscription} = subscription |> Subscriptions.admin_update_subscription(%{deer_tables_limit: 0})
      result = CsvImporter.run!(subscription, user, @polish_people_csv, "test.csv", "XYZ")

      assert all_records_for.(subscription.id) == []
      assert {:error, [{:deer_tables, _}]} = result
    end

    test "returns error when deer_columns_per_table_limit is being exceeded", %{subscription: subscription, user: user, all_records_for: all_records_for} do
      {:ok, subscription} = subscription |> Subscriptions.admin_update_subscription(%{deer_columns_per_table_limit: 1})

      {:ok, subscription} = Subscriptions.create_deer_table!(subscription, "example table", ["first column"]) # regression test
      result = CsvImporter.run!(subscription, user, @polish_people_csv, "test.csv", "XYZ")

      assert all_records_for.(subscription.id) == []
      assert {:error, [{:deer_tables, _}]} = result
    end

    test "returns error when deer_records_per_table_limit is being exceeded", %{subscription: subscription, user: user, all_records_for: all_records_for} do
      {:ok, subscription} = subscription |> Subscriptions.admin_update_subscription(%{deer_records_per_table_limit: 0})

      result = CsvImporter.run!(subscription, user, @polish_people_csv, "test.csv", "XYZ")

      assert all_records_for.(subscription.id) == []
      assert {:error, "Too many records: Limit is 0"} = result
    end
  end
end
