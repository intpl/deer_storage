defmodule PjeskiWeb.SessionControllerTest do
  use PjeskiWeb.ConnCase
  use Bamboo.Test

  alias Pjeski.Users

  import Pjeski.Fixtures

  describe "new" do
    test "[guest] GET /session/new", %{guest_conn: conn} do
      conn = get(conn, "/session/new")
      assert html_response(conn, 200) =~ "Zaloguj się do StorageDeer"
    end
  end

  describe "create" do
    test "[guest -> user] [valid] POST /session", %{guest_conn: conn} do
      user = create_valid_user_with_subscription()

      conn = post(conn, "/session", user: %{email: user.email, password: user.password})

      redirected_path = redirected_to(conn, 302)
      assert "/dashboard" = redirected_path
    end

    test "[guest -> user] [invalid - wrong password] POST /session", %{guest_conn: conn} do
      user = create_valid_user_with_subscription()

      conn = post(conn, "/session", user: %{email: user.email, password: "wrong"})

      assert html_response(conn, 200) =~ "Zły e-mail lub hasło"
    end

    test "[guest -> user] [valid - expired subscription] POST /session", %{guest_conn: conn} do
      user = create_user_with_expired_subscription()

      conn = post(conn, "/session", user: %{email: user.email, password: user.password})


      redirected_path = redirected_to(conn, 302)
      assert "/dashboard" = redirected_path
    end

    test "[guest -> user] [valid - empty subscription] POST /session", %{guest_conn: conn} do
      user = create_user_without_subscription()
      conn = post(conn, "/session", user: %{email: user.email, password: user.password})

      redirected_path = redirected_to(conn, 302)
      assert "/dashboard" = redirected_path
    end

    test "[guest -> user] [invalid - unconfirmed email] POST /session", %{guest_conn: conn} do
      user = create_valid_user_with_unconfirmed_email()

      conn = post(conn, "/session", user: %{email: user.email, password: user.password})

      redirected_path = redirected_to(conn, 302)
      assert "/session/new" = redirected_path
      conn = get(recycle(conn), redirected_path)

      assert html_response(conn, 200) =~ "Adres e-mail nie został potwierdzony. Wysłano linka ponownie"
    end

    test "[guest -> admin] [valid / assigned subscription] POST /session", %{guest_conn: conn} do
      {:ok, user} = create_valid_user_with_subscription() |> Users.toggle_admin

      conn = post(conn, "/session", user: %{email: user.email, password: user.password})

      redirected_path = redirected_to(conn, 302)
      assert "/dashboard" = redirected_path
    end

    test "[guest -> admin] [valid / expired subscription] POST /session", %{guest_conn: conn} do
      {:ok, user} = create_user_with_expired_subscription() |> Users.toggle_admin

      conn = post(conn, "/session", user: %{email: user.email, password: user.password})

      redirected_path = redirected_to(conn, 302)
      assert "/dashboard" = redirected_path
    end

    test "[guest -> admin] [valid / no subscription] POST /session", %{guest_conn: conn} do
      {:ok, user} = create_user_without_subscription() |> Users.toggle_admin

      conn = post(conn, "/session", user: %{email: user.email, password: user.password})

      redirected_path = redirected_to(conn, 302)
      assert "/admin/dashboard" = redirected_path
    end

    test "[guest -> admin] [valid / assigned subscription, unconfirmed email] POST /session", %{guest_conn: conn} do
      {:ok, user} = create_valid_user_with_unconfirmed_email() |> Users.toggle_admin

      conn = post(conn, "/session", user: %{email: user.email, password: user.password})

      redirected_path = redirected_to(conn, 302)
      assert "/dashboard" = redirected_path
    end
  end

  describe "delete" do
    test "[user] DELETE /session", %{guest_conn: conn} do
      user = create_valid_user_with_subscription()
      conn = post(conn, "/session", user: %{email: user.email, password: user.password})

      conn = delete(conn, "/session")
      redirected_path = redirected_to(conn, 302)
      assert "/" = redirected_path
    end
  end
end
