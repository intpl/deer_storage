defmodule Pjeski.DeerRecordsTest do
  use Pjeski.DataCase
  import Pjeski.DeerFixtures

  alias Pjeski.DeerRecords
  alias Pjeski.DeerRecords.DeerRecord

  describe "changeset/3" do
    setup do
      {:ok, subscription: create_valid_subscription_with_tables(1, 2)}
    end

    test "valid attrs", %{subscription: %{deer_tables: [deer_table]} = subscription} do
      attrs = %{
        deer_table_id: deer_table.id,
        deer_fields: [
          %{
            content: "Example content 1",
            deer_column_id: List.first(deer_table.deer_columns).id
          }
        ]
      }

      assert DeerRecord.changeset(%DeerRecord{}, attrs, subscription).valid? == true
    end

    test "invalid deer_table_id", %{subscription: %{deer_tables: [deer_table]} = subscription} do
      attrs = %{
        deer_table_id: "INVALID",
        deer_fields: [
          %{
            content: "Example content 1",
            deer_column_id: List.first(deer_table.deer_columns).id
          }
        ]
      }

      assert DeerRecord.changeset(%DeerRecord{}, attrs, subscription).valid? == false
    end

    test "invalid deer_column_id", %{subscription: %{deer_tables: [deer_table]} = subscription} do
      attrs = %{
        deer_table_id: deer_table.id,
        deer_fields: [
          %{
            content: "Example content 1",
            deer_column_id: "INVALID"
          }
        ]
      }

      assert DeerRecord.changeset(%DeerRecord{}, attrs, subscription).valid? == false
    end
  end

  describe "get_record!/2" do
    setup do
      subscription = create_valid_subscription_with_tables(1)

      {:ok,
       subscription: subscription,
       records_for_subscription: create_valid_records_for_subscription(subscription, 5),
      }
    end

    test "valid id and subscription_id", %{subscription: subscription, records_for_subscription: records} do
      first_record = List.first(records)
      result = DeerRecords.get_record!(first_record.id, subscription)

      assert first_record == result
    end
  end

  describe "list_records/1" do
    setup do
      subscription1 = create_valid_subscription_with_tables(1)
      subscription2 = create_valid_subscription_with_tables(1)

      {:ok,
       subscription1: subscription1,
       subscription2: subscription2,
       records_for_subscription1: create_valid_records_for_subscription(subscription1, 5),
       records_for_subscription2: create_valid_records_for_subscription(subscription2, 1)
      }
    end

    test "shows only records from requested subscription", %{subscription1: subscription, records_for_subscription1: records} do
      result = DeerRecords.list_records(subscription)

      assert length(result) == 5
      first_resulted_record = List.first(result)

      assert Enum.find(records, fn record -> record == first_resulted_record end)
    end
  end

  describe "update_record/3" do
    setup do
      subscription = create_valid_subscription_with_tables(2)

      {:ok,
       subscription: subscription,
       records_for_subscription: create_valid_records_for_subscription(subscription, 1),
      }
    end

    test "valid params", %{subscription: subscription, records_for_subscription: records_for_subscription} do
      record_to_be_updated = List.first(records_for_subscription)
      column_id = List.first(record_to_be_updated.deer_fields).deer_column_id

      {:ok, deer_record} = DeerRecords.update_record(
        record_to_be_updated,
        %{
          deer_table_id: record_to_be_updated.deer_table_id,
          deer_fields: [%{content: "Example content 1", deer_column_id: column_id}]
        },
        subscription
      )

      assert List.first(deer_record.deer_fields).content == "Example content 1"
    end
  end

  describe "create_record/2" do
    setup do
      {:ok, subscription: create_valid_subscription_with_tables(1, 2)}
    end

    test "valid tables and columns", %{subscription: %{deer_tables: [deer_table]} = subscription} do
      {:ok, deer_record} = DeerRecords.create_record(
        %{
          deer_table_id: deer_table.id,
          deer_fields: [
            %{
              content: "Example content 1",
              deer_column_id: List.first(deer_table.deer_columns).id
            },
            %{
              content: "Example content 2",
              deer_column_id: List.last(deer_table.deer_columns).id
            }
          ]
        },
        subscription
      )

      assert List.first(deer_record.deer_fields).content == "Example content 1"
      assert List.last(deer_record.deer_fields).content == "Example content 2"
    end

    test "record/fields with identical deer_column_id cannot be saved", %{subscription: %{deer_tables: [deer_table]} = subscription} do
      assert {:error, _} = DeerRecords.create_record(
        %{
          deer_table_id: deer_table.id,
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
        subscription
      )
    end
  end
end
