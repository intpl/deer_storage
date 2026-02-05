defmodule Mix.Tasks.DeerStorage.AddFakeredPeopleToSubscription do
  use Mix.Task
  import DeerStorage.Subscriptions
  import DeerStorage.DeerRecords

  @shortdoc "Upserts Fake People table to Subscription and creates random records"

  def run([subscription_id, count]) do
    Mix.Task.run("app.start")

    find_fake_people = fn deer_tables ->
      Enum.find(deer_tables, fn dt -> dt.name == "Fake People" end)
    end

    fill_fake_content = fn name ->
      case name do
        "Name" -> Faker.Person.name()
        "Age" -> Enum.random(18..70) |> Integer.to_string()
        "City" -> Faker.Address.city()
        "Country" -> Faker.Address.country()
        "Mobile phone" -> Faker.Phone.EnUs.phone()
      end
    end

    count = String.to_integer(count)
    subscription = String.to_integer(subscription_id) |> get_subscription!

    {subscription, deer_table} =
      case find_fake_people.(subscription.deer_tables) do
        nil ->
          {:ok, subscription} =
            create_deer_table!(subscription, "Fake People", [
              "Name",
              "Age",
              "City",
              "Country",
              "Mobile phone"
            ])

          {subscription, find_fake_people.(subscription.deer_tables)}

        fake_people ->
          {subscription, fake_people}
      end

    Enum.each(1..count, fn n ->
      deer_fields_arr =
        Enum.reduce(deer_table.deer_columns, [], fn %{id: deer_column_id, name: name}, arr ->
          [%{deer_column_id: deer_column_id, content: fill_fake_content.(name)} | arr]
        end)

      {:ok, _record} =
        create_record(
          subscription,
          %{
            deer_table_id: deer_table.id,
            deer_fields: deer_fields_arr
          }
        )

      Mix.shell().info(Integer.to_string(n))
    end)

    Mix.shell().info("Done.")
  end
end
