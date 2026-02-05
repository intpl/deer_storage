defmodule DeerStorage.DeerFixtures do
  alias DeerStorage.DeerRecords
  alias DeerStorage.Subscriptions
  alias DeerStorage.Subscriptions.Subscription

  def create_valid_subscription_with_tables(tables_count \\ 1, columns_count \\ 1) do
    deer_tables =
      Enum.map(1..tables_count, fn _ ->
        deer_columns =
          Enum.map(1..columns_count, fn _ -> %{name: Faker.Commerce.product_name_product()} end)

        %{name: Faker.Team.name(), deer_columns: deer_columns}
      end)

    {:ok, subscription} = Subscriptions.create_subscription(%{name: Faker.Company.catch_phrase()})

    {:ok, subscription_with_deer} =
      Subscriptions.update_subscription_deer(subscription, %{deer_tables: deer_tables})

    subscription_with_deer
  end

  def create_valid_records_for_subscription(
        %Subscription{deer_tables: deer_tables} = subscription,
        records_per_table_count \\ 1
      ) do
    grouped_records =
      Enum.map(deer_tables, fn %{id: table_id, deer_columns: deer_columns} ->
        Enum.map(1..records_per_table_count, fn n ->
          fields_attrs =
            Enum.map(deer_columns, fn %{id: column_id} ->
              %{deer_column_id: column_id, content: "Content #{n}"}
            end)

          {:ok, record} =
            DeerRecords.create_record(subscription, %{
              deer_table_id: table_id,
              deer_fields: fields_attrs
            })

          record
        end)
      end)

    List.flatten(grouped_records)
  end
end
