defmodule Pjeski.Fixtures do
  alias Pjeski.{Repo, Users, Subscriptions.Subscription}

  def subscription_attrs(), do: %Subscription{name: "Test", email: "test@storagedeer.com"}
  def user_attrs(), do: %{email: "test@storagedeer.com",
                        name: "Henryk Testowny",
                        password: "secret123",
                        email_confirmed_at: DateTime.utc_now,
                        email_confirmation_token: nil,
                        locale: "pl"}

  def create_expired_subscription, do: Subscription.admin_changeset(subscription_attrs(), %{expires_on: Date.add(Date.utc_today, -1)}) |> Repo.insert!
  def create_valid_subscription, do: Subscription.admin_changeset(subscription_attrs(), %{expires_on: Date.add(Date.utc_today, 1)}) |> Repo.insert!

  def create_valid_user_with_subscription, do: Users.admin_create_user(user_attrs() |> Map.merge(%{subscription_id: create_valid_subscription().id}))
  def create_valid_user_with_unconfirmed_email, do: Users.admin_create_user(user_attrs() |> Map.merge(%{subscription_id: create_valid_subscription().id, email_confirmed_at: nil, email_confirmation_token: "ABC"}))
  def create_user_with_expired_subscription, do: Users.admin_create_user(user_attrs() |> Map.merge(%{subscription_id: create_expired_subscription().id}))
  def create_user_without_subscription, do: Users.admin_create_user(user_attrs() |> Map.merge(%{subscription_id: nil}))
end
