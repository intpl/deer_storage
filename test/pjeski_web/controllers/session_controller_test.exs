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
      create_valid_user_with_subscription()

      conn = post(conn, "/session", user: %{email: user_attrs().email, password: user_attrs().password})

      redirected_path = redirected_to(conn, 302)
      assert "/dashboard" = redirected_path
    end

    test "[guest -> user] [invalid - empty params] POST /session", %{guest_conn: conn} do
      create_valid_user_with_subscription()

      conn = post(conn, "/session", user: %{})

      assert html_response(conn, 200) =~ "Zły e-mail lub hasło"
    end

    test "[guest -> user] [invalid - expired subscription] POST /session", %{guest_conn: conn} do
      create_user_with_expired_subscription()

      conn = post(conn, "/session", user: %{email: user_attrs().email, password: user_attrs().password})


      redirected_path = redirected_to(conn, 302)
      assert "/session/new" = redirected_path
      conn = get(recycle(conn), redirected_path)

      assert html_response(conn, 200) =~ "Twoja subskrypcja jest nieaktywna"
    end

    test "[guest -> user] [invalid - empty subscription] POST /session", %{guest_conn: conn} do
      create_user_without_subscription()

      conn = post(conn, "/session", user: %{email: user_attrs().email, password: user_attrs().password})

      redirected_path = redirected_to(conn, 302)
      assert "/session/new" = redirected_path
      conn = get(recycle(conn), redirected_path)

      assert html_response(conn, 200) =~ "Twoja subskrypcja jest nieaktywna"
    end

    test "[guest -> user] [invalid - unconfirmed email] POST /session", %{guest_conn: conn} do
      create_valid_user_with_unconfirmed_email()

      conn = post(conn, "/session", user: %{email: user_attrs().email, password: user_attrs().password})

      redirected_path = redirected_to(conn, 302)
      assert "/session/new" = redirected_path
      conn = get(recycle(conn), redirected_path)

      assert html_response(conn, 200) =~ "Adres e-mail nie został potwierdzony. Wysłano linka ponownie"
    end

    test "[guest -> admin] [valid] POST /session", %{guest_conn: conn} do
      {:ok, user} = create_valid_user_with_subscription()
      user |> Users.toggle_admin

      conn = post(conn, "/session", user: %{email: user_attrs().email, password: user_attrs().password})

      redirected_path = redirected_to(conn, 302)
      assert "/admin/dashboard" = redirected_path
    end

    test "[guest -> admin] [valid / expired subscription] POST /session", %{guest_conn: conn} do
      {:ok, user} = create_user_with_expired_subscription()
      user |> Users.toggle_admin

      conn = post(conn, "/session", user: %{email: user_attrs().email, password: user_attrs().password})

      redirected_path = redirected_to(conn, 302)
      assert "/admin/dashboard" = redirected_path
    end

    test "[guest -> admin] [valid / no subscription] POST /session", %{guest_conn: conn} do
      {:ok, user} = create_user_without_subscription()
      user |> Users.toggle_admin

      conn = post(conn, "/session", user: %{email: user_attrs().email, password: user_attrs().password})

      redirected_path = redirected_to(conn, 302)
      assert "/admin/dashboard" = redirected_path
    end

    test "[guest -> admin] [valid / unconfirmed email] POST /session", %{guest_conn: conn} do
      {:ok, user} = create_valid_user_with_unconfirmed_email()
      user |> Users.toggle_admin

      conn = post(conn, "/session", user: %{email: user_attrs().email, password: user_attrs().password})

      redirected_path = redirected_to(conn, 302)
      assert "/admin/dashboard" = redirected_path
    end
  end

  describe "delete" do
    test "[user] POST /session", %{user_conn: conn} do
      conn = delete(conn, "/session")

      redirected_path = redirected_to(conn, 302)
      assert "/" = redirected_path
    end
  end
end
