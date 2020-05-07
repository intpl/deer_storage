defmodule Pjeski.SubscriptionDeerTablesTest do
  use Pjeski.DataCase

  alias Pjeski.Subscriptions

  describe "deer_changeset" do
    test "example tables and columns" do
      {:ok, sub} = Subscriptions.create_subscription(%{name: "Test Subscription"})
      {:ok, sub_with_deer} = Subscriptions.update_subscription_deer(
        sub,
        %{deer_tables:
          [
            %{
              name: "Example table 1",
              deer_columns: [
                %{name: "Example table 1, column 1"}
              ]
            },
            %{name: "Example table 2",
              deer_columns: [
                %{name: "Example table 2, column 1"}
              ]
            }
          ]
        }
      )

      assert List.first(sub_with_deer.deer_tables).name == "Example table 1"
      assert List.first(List.first(sub_with_deer.deer_tables).deer_columns).name == "Example table 1, column 1"

      assert List.last(sub_with_deer.deer_tables).name == "Example table 2"
      assert List.first(List.last(sub_with_deer.deer_tables).deer_columns).name == "Example table 2, column 1"
    end
  end
end
