defmodule Pjeski.SharedRecordsTest do
  use Pjeski.DataCase
  import Pjeski.Fixtures
  import Pjeski.DeerFixtures
  import Pjeski.Users, only: [upsert_subscription_link!: 3]

  alias Pjeski.SharedRecords

  describe "create_record!/3 and get_record!/2" do
    setup do
      subscription = create_valid_subscription_with_tables(1, 2)
      user = create_user_without_subscription()

      upsert_subscription_link!(user.id, subscription.id, :raise)

      [record] = create_valid_records_for_subscription(subscription)

      {:ok, user: user, subscription: subscription, record: record}
    end

    test "valid attrs", %{subscription: subscription, user: user, record: record} do
      created_record = SharedRecords.create_record!(subscription.id, user.id, record.id)

      loaded_record = SharedRecords.get_record!(subscription.id, created_record.id)

      assert loaded_record.deer_record_id == record.id
    end
  end
end
