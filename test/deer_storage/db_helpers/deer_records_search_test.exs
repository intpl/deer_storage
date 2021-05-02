defmodule DeerStorage.DeerRecordsSearchTest do
  use DeerStorage.DataCase
  import DeerStorage.DeerFixtures

  alias DeerStorage.DbHelpers.DeerRecordsSearch

  describe "search_records/4" do
    test "composing" do
      subscription = create_valid_subscription_with_tables(2, 2)
      deer_table = subscription.deer_tables |> List.first
      create_valid_records_for_subscription(subscription, 3) # therefore total records count is 6

      result = DeerRecordsSearch.search_records(subscription.id, deer_table.id, ["Content"], 1)
      assert length(result) == 3

      result2 = DeerRecordsSearch.search_records(subscription.id, deer_table.id, ["Content", "1"], 1)
      assert length(result2) == 1

      result3 = DeerRecordsSearch.search_records(subscription.id, deer_table.id, ["non-existing-content"], 1)
      assert Enum.empty?(result3)
    end
  end
end
