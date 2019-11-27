alias Pjeski.Repo
alias Pjeski.Users.User
alias Pjeski.Subscriptions.Subscription
alias Pjeski.UserClients.Client

Repo.delete_all(Client)
Repo.delete_all(User)
Repo.delete_all(Subscription)

admin_emails = ["marek@wesolowski.eu.org", "bgladecki@gmail.com"]
subscription_emails = ["roman@dmowski.pl", "roman@polanski.pl"] ++ Enum.map((1..100), fn _ -> Faker.Internet.safe_email() end)
default_user_map = %{password: "dupadupa", admin_notes: "Generated automatically"}

Enum.map((admin_emails), fn admin_email ->
  Repo.insert!(
    User.admin_changeset(%User{},
      Map.merge(%{
            email: admin_email,
            name: "Admin " <> Faker.Name.name(),
            locale: :pl,
            role: "admin"},
        default_user_map)))
end)

Enum.map((subscription_emails), fn subscription_email ->
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
              locale: Enum.random([:en, :pl]),
              subscription_id: subscription.id
                  }, default_user_map)))

  IO.puts "Created user: #{first_user.name} (#{first_user.email})"

  Enum.map((0..:rand.uniform(30)), fn _ ->
    user = Repo.insert!(
      User.admin_changeset(%User{},
        Map.merge(%{
              email: Faker.Internet.safe_email(),
              name: Faker.Name.name(),
              locale: Enum.random([:en, :pl]),
              subscription_id: subscription.id
                  }, default_user_map)))
    IO.puts "Created user: #{user.name} (#{user.email})"

    Enum.map((0..:rand.uniform(100)), fn _ ->
      client = Repo.insert!(%Client{
          address: Faker.Address.street_address(),
          city: Faker.Address.city(),
          email: Faker.Internet.safe_email(),
          name: Faker.Name.name(),
          notes: Faker.Lorem.Shakespeare.as_you_like_it(),
          phone: Faker.Phone.EnGb.mobile_number(),
          user_id: user.id,
          subscription_id: subscription.id
                            })
      IO.puts "Created client: #{client.name} (#{client.email})"
    end)
  end)
end)
