defmodule Mix.Tasks.Pjeski.AddFakeredCarsToSubscription do
  use Mix.Task
  import Pjeski.Subscriptions
  import Pjeski.DeerRecords

  @shortdoc "Upserts Fake Cars table to Subscription and creates random records"

  def run([subscription_id, count]) do
    Mix.Task.run "app.start"

    find_fake_cars = fn deer_tables -> Enum.find(deer_tables, fn dt -> dt.name == "Fake cars" end) end
    fill_fake_content = fn name ->
      case name do
        "Make and model" -> Faker.Vehicle.make_and_model()
        "Year" -> Enum.random(1970..2020) |> Integer.to_string
        "Transmission" -> Faker.Vehicle.transmission()
        "Fuel type" -> Faker.Vehicle.fuel_type()
        "VIN" -> Faker.Vehicle.vin()
        "Drivetrain" -> Faker.Vehicle.drivetrain()
        "Specification" -> Faker.Vehicle.standard_specs() |> Enum.join(", ")
      end
    end

    count = String.to_integer(count)
    subscription = String.to_integer(subscription_id) |> get_subscription!

    {subscription, deer_table} = case find_fake_cars.(subscription.deer_tables) do
                   nil ->
                     {:ok, subscription} = create_deer_table!(subscription, "Fake cars",
                     ["Make and model", "Year", "Transmission", "Fuel type", "VIN", "Drivetrain", "Specification"])

                     {subscription, find_fake_cars.(subscription.deer_tables)}
                   fake_cars -> {subscription, fake_cars}
                 end

    Enum.each(1..count, fn n ->
      deer_fields_arr = Enum.reduce(deer_table.deer_columns, [], fn(%{id: deer_column_id, name: name}, arr) ->
        [%{deer_column_id: deer_column_id, content: fill_fake_content.(name)} | arr]
      end)

      {:ok, _record} = create_record(
        subscription, %{
          deer_table_id: deer_table.id,
          deer_fields: deer_fields_arr
        }
      )

      Mix.shell.info Integer.to_string(n)
    end)

    Mix.shell.info "Done."
  end
end
