defmodule Pjeski.SubscriptionTest do
  use Pjeski.DataCase

  alias Pjeski.Subscriptions.Subscription

  describe "subscriptions" do
    alias Pjeski.Subscriptions.Subscription

    @valid_attrs %{email: "asd@asd.pl", expires_on: ~N[2010-04-17 14:00:00]}
    @update_attrs %{email: "qwe@qwe.pl", expires_on: ~N[2011-05-18 15:01:01]}
    @invalid_attrs %{email: "invalid format nanana", expires_on: ~N[2011-05-18 15:01:01]}

    def subscription_fixture(attrs \\ %{}) do
      {:ok, subscription} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Subscription.create_subscription()

      subscription
    end

    test "list_subscriptions/0 returns all subscriptions" do
      subscription = subscription_fixture()
      assert Subscription.list_subscriptions() == [subscription]
    end

    test "get_subscription!/1 returns the subscription with given id" do
      subscription = subscription_fixture()
      assert Subscription.get_subscription!(subscription.id) == subscription
    end

    test "create_subscription/1 with valid data creates a subscription" do
      assert {:ok, %Subscription{} = subscription} = Subscription.create_subscription(@valid_attrs)
      assert subscription.email == "asd@asd.pl"
      assert subscription.expires_on == ~N[2010-04-17 14:00:00]
    end

    test "create_subscription/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Subscription.create_subscription(@invalid_attrs)
    end

    test "update_subscription/2 with valid data updates the subscription" do
      subscription = subscription_fixture()
      assert {:ok, %Subscription{} = subscription} = Subscription.update_subscription(subscription, @update_attrs)
      assert subscription.email == "qwe@qwe.pl"
      assert subscription.expires_on == ~N[2011-05-18 15:01:01]
    end

    test "update_subscription/2 with invalid data returns error changeset" do
      subscription = subscription_fixture()
      assert {:error, %Ecto.Changeset{}} = Subscription.update_subscription(subscription, @invalid_attrs)
      assert subscription == Subscription.get_subscription!(subscription.id)
    end

    test "delete_subscription/1 deletes the subscription" do
      subscription = subscription_fixture()
      assert {:ok, %Subscription{}} = Subscription.delete_subscription(subscription)
      assert_raise Ecto.NoResultsError, fn -> Subscription.get_subscription!(subscription.id) end
    end

    test "change_subscription/1 returns a subscription changeset" do
      subscription = subscription_fixture()
      assert %Ecto.Changeset{} = Subscription.change_subscription(subscription)
    end
  end
end
