defmodule Pjeski.SubscriptionDeerTablesTest do
  use Pjeski.DataCase
  import Pjeski.DeerFixtures

  describe "deer_changeset" do
    test "example tables and columns" do
      subscription = create_valid_subscription_with_tables(2, 2)

      assert length(subscription.deer_tables) == 2
      assert length(List.first(subscription.deer_tables).deer_columns) == 2
    end
  end
end
