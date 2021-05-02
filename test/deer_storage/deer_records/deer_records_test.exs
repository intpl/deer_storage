defmodule DeerStorage.DeerRecordsTest do
  use DeerStorage.DataCase
  import DeerStorage.DeerFixtures

  alias DeerStorage.DeerRecords
  alias DeerStorage.DeerRecords.DeerRecord

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
      result = DeerRecords.get_record!(subscription.id, first_record.id)

      assert first_record == result
    end
  end

  describe "update_record/3" do
    setup do
      subscription = create_valid_subscription_with_tables(2, 3)
      record = create_valid_records_for_subscription(subscription, 1) |> List.first

      {:ok,
       subscription: subscription,
       target_record: record,
       first_column_id: Enum.at(record.deer_fields, 0).deer_column_id,
       second_column_id: Enum.at(record.deer_fields, 1).deer_column_id,
       third_column_id: Enum.at(record.deer_fields, 2).deer_column_id
      }
    end

    test "valid params -> same order", %{subscription: subscription, target_record: target_record, first_column_id: first_column_id, second_column_id: second_column_id} do
      {:ok, deer_record} = DeerRecords.update_record(
        subscription,
        target_record,
        %{
          deer_table_id: target_record.deer_table_id,
          deer_fields: [
            %{content: "Example content 1", deer_column_id: first_column_id},
            %{content: "Example content 2", deer_column_id: second_column_id}
          ]
        }
      )

      assert Enum.at(deer_record.deer_fields, 0).content == "Example content 1"
      assert Enum.at(deer_record.deer_fields, 1).content == "Example content 2"
    end

    test "valid params -> change order", %{subscription: subscription, target_record: target_record, first_column_id: first_column_id, second_column_id: second_column_id, third_column_id: third_column_id} do
      {:ok, deer_record} = DeerRecords.update_record(
        subscription,
        target_record,
        %{
          deer_table_id: target_record.deer_table_id,
          deer_fields: [
            %{content: "Example content 3", deer_column_id: third_column_id},
            %{content: "Example content 2", deer_column_id: second_column_id},
            %{content: "Example content 1", deer_column_id: first_column_id}
          ]
        }
      )

      assert Enum.at(deer_record.deer_fields, 0).content == "Example content 3"
      assert Enum.at(deer_record.deer_fields, 1).content == "Example content 2"
      assert Enum.at(deer_record.deer_fields, 2).content == "Example content 1"
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

  describe "connect_records/3 and disconnect_records!/3" do
    setup do
      subscription = create_valid_subscription_with_tables(1)

      {:ok,
       subscription: subscription,
       records_for_subscription: create_valid_records_for_subscription(subscription, 2),
      }
    end

    test "connect and disconnect records", %{subscription: subscription, records_for_subscription: records} do
      [r1, r2] = records

      DeerRecords.connect_records!(r1, r2, subscription.id)

      assert DeerRecords.get_record!(subscription.id, r1.id).connected_deer_records_ids == [r2.id]
      assert DeerRecords.get_record!(subscription.id, r2.id).connected_deer_records_ids == [r1.id]

      DeerRecords.disconnect_records!(r1, r2, subscription.id)

      assert DeerRecords.get_record!(subscription.id, r1.id).connected_deer_records_ids == []
      assert DeerRecords.get_record!(subscription.id, r2.id).connected_deer_records_ids == []
    end

    test "cannot connect record to itself", %{subscription: subscription, records_for_subscription: [record, _]} do
      assert_raise RuntimeError, fn -> DeerRecords.connect_records!(record, record, subscription.id) end
    end
  end
end
