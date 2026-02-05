defmodule DeerCacheRecordsCountsCacheTest do
  use DeerStorage.DataCase
  import DeerStorage.DeerFixtures

  describe "fetch_count/1" do
    test "responds with 0 when invalid id" do
      assert DeerCache.RecordsCountsCache.fetch_count("invalid") == 0
    end

    test "responds with count when deer records exist" do
      subscription = create_valid_subscription_with_tables(2)
      create_valid_records_for_subscription(subscription, 5)

      deer_tables_ids = subscription.deer_tables |> Enum.map(fn dt -> dt.id end)

      Enum.each(deer_tables_ids, fn id ->
        assert DeerCache.RecordsCountsCache.fetch_count(id) == 5
      end)
    end

    test "tracks counts after record create/delete" do
      subscription = create_valid_subscription_with_tables()

      [%{deer_table_id: table_id} = first_record | _] =
        create_valid_records_for_subscription(subscription, 5)

      assert DeerCache.RecordsCountsCache.fetch_count(table_id) == 5

      create_valid_records_for_subscription(subscription, 5)
      assert DeerCache.RecordsCountsCache.fetch_count(table_id) == 10

      DeerStorage.DeerRecords.delete_record(subscription, first_record)
      assert DeerCache.RecordsCountsCache.fetch_count(table_id) == 9
    end
  end
end
