defmodule Pjeski.Fixtures do
  alias Pjeski.{Repo, Users, Subscriptions.Subscription}

  def random_subscription_attrs(), do: %Subscription{name: Faker.Name.name()}
  def random_user_attrs(), do: %{email: Faker.Internet.safe_email(),
                        name: Faker.Name.name(),
                        password: "secret123",
                        email_confirmed_at: DateTime.utc_now,
                        email_confirmation_token: nil,
                        locale: "pl"}

  def create_expired_subscription(attrs), do: Subscription.admin_changeset(attrs, %{expires_on: Date.add(Date.utc_today, -1)}) |> Repo.insert
  def create_valid_subscription(attrs), do: Subscription.admin_changeset(attrs, %{expires_on: Date.add(Date.utc_today, 1)}) |> Repo.insert

  def create_valid_user_with_subscription(user_attrs \\ random_user_attrs(), subscription_attrs \\ random_subscription_attrs()) do
    {:ok, subscription} = create_valid_subscription(subscription_attrs)
    {:ok, user} = Users.admin_create_user(user_attrs |> Map.merge(%{subscription_id: subscription.id}))

    user
  end

  def create_valid_user_with_unconfirmed_email(attrs \\ random_user_attrs(), subscription_attrs \\ random_subscription_attrs()) do
    {:ok, subscription} = create_valid_subscription(subscription_attrs)
    {:ok, user} = Users.admin_create_user(attrs |> Map.merge(%{subscription_id: subscription.id, email_confirmed_at: nil, email_confirmation_token: "ABC"}))

    user
  end

  def create_user_with_expired_subscription(attrs \\ random_user_attrs(), subscription_attrs \\ random_subscription_attrs()) do
    {:ok, subscription} = create_expired_subscription(subscription_attrs)
    {:ok, user} = Users.admin_create_user(attrs |> Map.merge(%{subscription_id: subscription.id}))

    user
  end

  def create_user_without_subscription(attrs \\ random_user_attrs()) do
    {:ok, user} = Users.admin_create_user(attrs |> Map.merge(%{subscription_id: nil}))
    user
  end
end
