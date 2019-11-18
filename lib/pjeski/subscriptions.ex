defmodule Pjeski.Subscriptions do

  import Ecto.Query, warn: false
  alias Pjeski.Repo

  alias Pjeski.Subscriptions.Subscription

  def list_subscriptions do
    Subscription
    |> Repo.all
    |> Repo.preload(:users)
  end

  def get_subscription!(id) do
    Subscription
    |> Repo.get!(id)
    |> Repo.preload(:users)
  end

  def create_subscription(attrs \\ %{}) do
    %Subscription{}
    |> Subscription.changeset(attrs)
    |> Repo.insert()
  end

  def update_subscription(%Subscription{} = subscription, attrs) do
    subscription
    |> Subscription.changeset(attrs)
    |> Repo.update()
  end

  def delete_subscription(%Subscription{} = subscription) do
    Repo.delete(subscription)
  end

  def change_subscription(%Subscription{} = subscription) do
    Subscription.changeset(subscription, %{})
  end

  def demo_subscription_changeset_for_user(user_attrs) do
    %Subscription{
      email: user_attrs.email,
      name: user_attrs.name,
      expires_on: Date.add(Date.utc_today, 14)
    }
  end
end
