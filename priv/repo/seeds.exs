alias Pjeski.Repo

alias Pjeski.Users
alias Pjeski.Subscriptions
alias Pjeski.UserAvailableSubscriptionLinks.UserAvailableSubscriptionLink

alias Pjeski.Users.User
alias Pjeski.Subscriptions.Subscription

import Ecto.Query, warn: false

Repo.delete_all(User)
Repo.delete_all(Subscription)

Logger.configure([level: :warning])

datetime = fn -> DateTime.truncate(DateTime.utc_now(), :second) end
naive_datetime = fn -> NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second) end

admin_emails = ["bgladecki@gmail.com", "marek@weczmarski.com"]
subscription_names = Enum.map((500..1000), fn _ -> Faker.Company.catch_phrase() end) |> Enum.uniq
default_user_map = %{password: "dupadupa", admin_notes: "Generated automatically"}

built_admin_structs = Enum.map(admin_emails, fn admin_email ->
  params = Map.merge(
  %{
    email: admin_email,
    name: "Admin " <> Faker.Name.name(),
    locale: "pl",
    role: "admin"}, default_user_map)

  User.admin_changeset(%User{}, params).changes |> Map.delete(:password) |> Map.merge(%{inserted_at: naive_datetime.(), updated_at: naive_datetime.(), email_confirmed_at: datetime.()})
end)

IO.write "Inserting Admin structs"
Repo.insert_all(User, built_admin_structs)
IO.puts " OK"

built_subscription_structs = Enum.map(subscription_names, fn subscription_name ->
  Subscription.admin_changeset(%Subscription{},
    %{
      name: subscription_name,
      time_zone: Enum.random(Tzdata.zone_list),
      admin_notes: "Generated automatically",
      expires_on: Date.add(Date.utc_today, 90)
    }).changes |> Map.merge(%{inserted_at: naive_datetime.(), updated_at: naive_datetime.()})
end)

IO.write "Inserting Subscription structs"
Repo.insert_all(Subscription, built_subscription_structs)
IO.puts " OK"

subscriptions = Subscription |> select([:id]) |> Repo.all

for %Subscription{id: sub_id} <- subscriptions do
    IO.write "Generating users structs for subscription #{sub_id}"

    built_users_for_current_subscription = [
      User.admin_changeset(%User{}, Map.merge(
            %{
              email: Faker.Internet.safe_email(),
              name: Faker.Name.name(),
              time_zone: Enum.random(Tzdata.zone_list),
              locale: Enum.random(["en", "pl"]),
              subscription_id: sub_id,
              email_confirmed_at: datetime.()
            }, default_user_map
          )
      ).changes |> Map.delete(:password) |> Map.merge(%{inserted_at: naive_datetime.(), updated_at: naive_datetime.()})
    ] ++ Enum.map((0..:rand.uniform(60)), fn _ ->
      IO.write(".")

      User.admin_changeset(%User{}, Map.merge(
            %{
              email: Faker.Internet.safe_email(),
              name: Faker.Name.name(),
              time_zone: Enum.random(Tzdata.zone_list),
              locale: Enum.random(["en", "pl"]),
              subscription_id: sub_id,
              email_confirmed_at: datetime.()
            }, default_user_map)
      ).changes |> Map.delete(:password) |> Map.merge(%{inserted_at: naive_datetime.(), updated_at: naive_datetime.()})
    end)
    |> List.flatten

    IO.puts " OK"
    IO.write "Inserting users structs for subscription #{sub_id}"

    {count, users} = Repo.insert_all(User, built_users_for_current_subscription, on_conflict: :nothing, returning: true)

    IO.puts " OK (inserted #{count} users)"
    IO.write "Inserting user<->subscription links"

    user_subscription_links = Enum.map(users, fn user ->
      %{user_id: user.id, subscription_id: user.subscription_id, inserted_at: naive_datetime.(), updated_at: naive_datetime.()}
    end)

    Repo.insert_all(UserAvailableSubscriptionLink, user_subscription_links)

    IO.puts " OK"
    IO.puts "Current User count: #{Pjeski.Repo.aggregate(from(u in "users"), :count, :id)}"
end

IO.puts "Done!"
IO.puts "TOTAL Subscription count: #{Subscriptions.total_count}"
IO.puts "TOTAL User count: #{Users.total_count}"
