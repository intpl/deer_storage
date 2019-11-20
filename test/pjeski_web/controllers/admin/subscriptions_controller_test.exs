defmodule PjeskiWeb.Admin.SubscriptionControllerTest do
  use PjeskiWeb.ConnCase

  alias Pjeski.Subscriptions

  @create_attrs %{name: "example name", email: "test@test.eu"}
  @update_attrs %{email: "test2@test.eu"}

  def fixture(:subscription) do
    {:ok, subscription} = Subscriptions.create_subscription(@create_attrs)
    subscription
  end

  describe "index" do
    test "lists all subscriptions", %{admin_conn: admin_conn} do
      conn = get(admin_conn, Routes.admin_subscription_path(admin_conn, :index))
      assert html_response(conn, 200) =~ "Subscription name"
    end
  end

  describe "new subscription" do
    test "renders form", %{admin_conn: admin_conn} do
      conn = get(admin_conn, Routes.admin_subscription_path(admin_conn, :new))
      assert html_response(conn, 200) =~ "New Subscription"
    end
  end

  describe "create subscription" do
    test "redirects to show when data is valid", %{admin_conn: admin_conn} do
      conn = post(admin_conn, Routes.admin_subscription_path(admin_conn, :create), subscription: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.admin_subscription_path(conn, :show, id)

      conn = get(admin_conn, Routes.admin_subscription_path(admin_conn, :show, id))
      assert html_response(conn, 200) =~ "example name"
    end
  end

  describe "edit subscription" do
    setup [:create_subscription]

    test "renders form for editing chosen subscription", %{admin_conn: admin_conn, subscription: subscription} do
      conn = get(admin_conn, Routes.admin_subscription_path(admin_conn, :edit, subscription))
      assert html_response(conn, 200) =~ "example name"
    end
  end

  describe "update subscription" do
    setup [:create_subscription]

    test "redirects when data is valid", %{admin_conn: admin_conn, subscription: subscription} do
      conn = put(admin_conn, Routes.admin_subscription_path(admin_conn, :update, subscription), subscription: @update_attrs)
      assert redirected_to(conn) == Routes.admin_subscription_path(admin_conn, :show, subscription)

      conn = get(admin_conn, Routes.admin_subscription_path(admin_conn, :show, subscription))
      assert html_response(conn, 200) =~ "test2@test.eu"
    end
  end

  describe "delete subscription" do
    setup [:create_subscription]

    test "deletes chosen subscription", %{admin_conn: admin_conn, subscription: subscription} do
      conn = delete(admin_conn, Routes.admin_subscription_path(admin_conn, :delete, subscription))
      assert redirected_to(conn) == Routes.admin_subscription_path(admin_conn, :index)
      assert_error_sent 404, fn ->
        get(admin_conn, Routes.admin_subscription_path(admin_conn, :show, subscription))
      end
    end
  end

  defp create_subscription(_) do
    subscription = fixture(:subscription)
    {:ok, subscription: subscription}
  end
end
