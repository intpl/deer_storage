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
      result = DeerRecords.get_record!(subscription, first_record.id)

      assert first_record == result
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
        subscription,
        record_to_be_updated,
        %{
          deer_table_id: record_to_be_updated.deer_table_id,
          deer_fields: [%{content: "Example content 1", deer_column_id: column_id}]
        }
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
        subscription,
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
        }
      )

      assert List.first(deer_record.deer_fields).content == "Example content 1"
      assert List.last(deer_record.deer_fields).content == "Example content 2"
    end

    test "record/fields with identical deer_column_id cannot be saved", %{subscription: %{deer_tables: [deer_table]} = subscription} do
      assert {:error, _} = DeerRecords.create_record(
        subscription,
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
        }
      )
    end
  end
end
