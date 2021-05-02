defmodule DeerStorageWeb.Admin.SubscriptionControllerTest do
  use DeerStorageWeb.ConnCase

  alias DeerStorage.Repo
  alias DeerStorage.Users
  alias DeerStorage.Subscriptions
  alias DeerStorage.Subscriptions.Subscription

  import DeerStorage.Test.SessionHelpers, only: [assign_user_to_session: 2]

  @admin_attrs %{email: "admin@storagedeer.com",
                  name: "Admin",
                  password: "secret123",
                  password_confirmation: "secret123",
                  locale: "pl",
  }

  @create_attrs %{name: "example name", email: "test@test.eu"}
  @update_attrs %{name: "example2 name"}

  setup do
    {:ok, admin} = Users.admin_create_user(@admin_attrs |> Map.merge(%{role: "admin"}))
    {:ok, admin: admin}
  end

  def fixture(:subscription) do
    {:ok, subscription} = Subscriptions.create_subscription(@create_attrs)
    subscription
  end

  describe "index" do
    setup [:create_subscription]

    test "lists all subscriptions", %{conn: conn, admin: admin} do
      conn = assign_user_to_session(conn, admin)
      conn = get(conn, Routes.admin_subscription_path(conn, :index))

      assert html_response(conn, 200) =~ "Nazwa subskrypcji"
      assert html_response(conn, 200) =~ "example name"
    end
  end

  describe "new subscription" do
    test "renders form", %{conn: conn, admin: admin} do
      conn = assign_user_to_session(conn, admin)
      conn = get(conn, Routes.admin_subscription_path(conn, :new))

      assert html_response(conn, 200) =~ "Nowa Subskrypcja"
    end
  end

  describe "create subscription" do
    test "redirects to show when data is valid", %{conn: conn, admin: admin} do
      conn = assign_user_to_session(conn, admin)
      conn = post(conn, Routes.admin_subscription_path(conn, :create), subscription: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.admin_subscription_path(conn, :show, id)

      assert Repo.get!(Subscription, id).name == "example name"
    end
  end

  describe "edit subscription" do
    setup [:create_subscription]

    test "renders form for editing chosen subscription", %{conn: conn, admin: admin, subscription: subscription} do
      conn = assign_user_to_session(conn, admin)
      conn = get(conn, Routes.admin_subscription_path(conn, :edit, subscription))

      assert html_response(conn, 200) =~ "example name"
    end
  end

  describe "update subscription" do
    setup [:create_subscription]

    test "redirects when data is valid", %{conn: conn, admin: admin, subscription: subscription} do
      conn = assign_user_to_session(conn, admin)
      conn = put(conn, Routes.admin_subscription_path(conn, :update, subscription), subscription: @update_attrs)

      assert redirected_to(conn) == Routes.admin_subscription_path(conn, :show, subscription)

      assert Repo.get!(Subscription, subscription.id).name == "example2 name"
    end
  end

  describe "delete subscription" do
    setup [:create_subscription]

    test "deletes chosen subscription", %{conn: conn, admin: admin, subscription: subscription} do
      conn = assign_user_to_session(conn, admin)
      conn = delete(conn, Routes.admin_subscription_path(conn, :delete, subscription))

      assert redirected_to(conn) == Routes.admin_subscription_path(conn, :index)
      assert Repo.get(Subscription, subscription.id) == nil
    end
  end

  defp create_subscription(_), do: {:ok, subscription: fixture(:subscription)}
end
