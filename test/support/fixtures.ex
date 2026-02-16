defmodule DeerStorage.Fixtures do
  alias DeerStorage.{Repo, Users, Subscriptions.Subscription}

  def random_subscription_attrs(), do: %Subscription{name: Faker.Person.name()}

  def random_user_attrs(),
    do: %{
      email: Faker.Internet.safe_email(),
      name: Faker.Person.name(),
      password: "secret123",
      email_confirmed_at: DateTime.utc_now(),
      email_confirmation_token: nil,
      locale: "pl"
    }

  def create_expired_subscription(attrs),
    do:
      Subscription.admin_changeset(attrs, %{expires_on: Date.add(Date.utc_today(), -1)})
      |> Repo.insert()

  def create_valid_subscription(attrs),
    do:
      Subscription.admin_changeset(attrs, %{expires_on: Date.add(Date.utc_today(), 1)})
      |> Repo.insert()

  def create_valid_user_with_subscription(
        user_attrs \\ random_user_attrs(),
        subscription_attrs \\ random_subscription_attrs(),
        link_attrs \\ %{}
      ) do
    {:ok, subscription} = create_valid_subscription(subscription_attrs)

    # Create user without subscription first
    {:ok, user} =
      Users.admin_create_user(
        user_attrs
        |> Map.merge(%{last_used_subscription_id: nil})
      )

    # Manually create the subscription link with the desired permissions
    default_link_attrs = %{permission_to_manage_users: false}
    merged_link_attrs = Map.merge(default_link_attrs, link_attrs)

    Users.upsert_subscription_link!(user.id, subscription.id, :raise, merged_link_attrs)

    # Update user's last_used_subscription_id
    updated_user = Users.update_last_used_subscription_id!(user, subscription.id)

    # Preload the available_subscriptions association
    user_with_subscriptions = Repo.preload(updated_user, :available_subscriptions)

    # Return user with password stored in a map for testing
    Map.put(user_with_subscriptions, :password, user_attrs.password)
  end

  def create_valid_user_with_unconfirmed_email(
        attrs \\ random_user_attrs(),
        subscription_attrs \\ random_subscription_attrs()
      ) do
    {:ok, subscription} = create_valid_subscription(subscription_attrs)

    {:ok, user} =
      Users.admin_create_user(
        attrs
        |> Map.merge(%{
          last_used_subscription_id: subscription.id,
          email_confirmed_at: nil,
          email_confirmation_token: "ABC"
        })
      )

    Map.put(user, :password, attrs.password)
  end

  def create_user_with_expired_subscription(
        attrs \\ random_user_attrs(),
        subscription_attrs \\ random_subscription_attrs()
      ) do
    {:ok, subscription} = create_expired_subscription(subscription_attrs)

    {:ok, user} =
      Users.admin_create_user(attrs |> Map.merge(%{last_used_subscription_id: subscription.id}))

    Map.put(user, :password, attrs.password)
  end

  def create_user_without_subscription(attrs \\ random_user_attrs()) do
    {:ok, user} = Users.admin_create_user(attrs |> Map.merge(%{last_used_subscription_id: nil}))
    Map.put(user, :password, attrs.password)
  end
end
