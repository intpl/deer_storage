defmodule Pjeski.DeerRecordsTest do
  use Pjeski.DataCase

  alias Pjeski.DeerRecords
  alias Pjeski.Subscriptions

  describe "deer_changeset" do
    setup do
      {:ok, subscription} = Subscriptions.create_subscription(%{name: "Test Subscription"})
      {:ok, subscription: subscription}
    end

    test "valid tables and columns", %{subscription: subscription} do
      {:ok, deer_record} = DeerRecords.create_record(
        %{
          deer_table_id: "TABLE_ID",
          deer_fields: [
            %{
              content: "Example content 1",
              deer_column_id: "COLUMN_ID"
            },
            %{
              content: "Example content 2",
              deer_column_id: "COLUMN_ID2"
            }
          ]
        },
        subscription.id
      )

      assert List.first(deer_record.deer_fields).content == "Example content 1"
      assert List.last(deer_record.deer_fields).content == "Example content 2"
    end

    test "record/fields with identical deer_column_id cannot be saved", %{subscription: subscription} do
      assert {:error, _} = DeerRecords.create_record(
        %{
          deer_table_id: "TABLE_ID",
          deer_fields: [
            %{
              content: "Example content 1",
              deer_column_id: "INVALID_ID"
            },
            %{
              content: "Example content 2",
              deer_column_id: "INVALID_ID"
            }
          ]
        },
        subscription.id
      )
    end
  end
end
