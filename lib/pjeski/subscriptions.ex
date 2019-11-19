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

  def admin_create_subscription(attrs \\ %{}) do
    %Subscription{}
    |> Subscription.admin_changeset(attrs)
    |> Repo.insert()
  end

  def create_subscription(attrs \\ %{}) do
    %Subscription{}
    |> Subscription.changeset(attrs)
    |> Repo.insert()
  end

  def admin_update_subscription(%Subscription{} = subscription, attrs) do
    subscription
    |> Subscription.admin_changeset(attrs)
    |> Repo.update()
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

  def admin_change_subscription(%Subscription{} = subscription) do
    Subscription.admin_changeset(subscription, %{})
  end
end
