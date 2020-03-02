alias Pjeski.Repo
alias Pjeski.Users.User
alias Pjeski.Subscriptions.Subscription

Repo.delete_all(User)
Repo.delete_all(Subscription)

admin_emails = ["bgladecki@gmail.com"]
subscription_emails = ["roman@dmowski.pl", "roman@polanski.pl"] ++ Enum.map((1..100), fn _ -> Faker.Internet.safe_email() end)
default_user_map = %{password: "dupadupa", admin_notes: "Generated automatically"}

Enum.map((admin_emails), fn admin_email ->
  Repo.insert!(
    User.admin_changeset(%User{},
      Map.merge(%{
            email: admin_email,
            name: "Admin " <> Faker.Name.name(),
            locale: "pl",
            role: "admin"},
        default_user_map)))
end)

Enum.map(Enum.uniq(subscription_emails), fn subscription_email ->
  subscription = Repo.insert!(
    Subscription.admin_changeset(%Subscription{}, %{
      email: subscription_email,
      name: Faker.Company.catch_phrase(),
      time_zone: Enum.random(Tzdata.zone_list),
      admin_notes: "Generated automatically"
    }))

  IO.puts "Created subscription: #{subscription.name} (#{subscription.email})"

  first_user = Repo.insert!(
      User.admin_changeset(%User{},
      Map.merge(%{
              email: subscription_email,
              name: Faker.Name.name(),
              locale: Enum.random(["en", "pl"]),
              subscription_id: subscription.id
                  }, default_user_map)))

  IO.puts "Created user: #{first_user.name} (#{first_user.email})"

  Enum.map((0..:rand.uniform(30)), fn _ ->
    {_, user} = Repo.insert(
      User.admin_changeset(%User{},
        Map.merge(%{
              email: Faker.Internet.safe_email(),
              name: Faker.Name.name(),
              locale: Enum.random(["en", "pl"]),
              subscription_id: subscription.id
                  }, default_user_map)))

    IO.puts "Created user: #{user.name} (#{user.email}), state: #{Ecto.get_meta(user, :state)}"

    Enum.map((0..:rand.uniform(100)), fn _ ->
      IO.puts "Seed something here"
    end)
  end)
end)
