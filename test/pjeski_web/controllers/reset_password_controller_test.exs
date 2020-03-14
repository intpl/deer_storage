defmodule PjeskiWeb.ResetPasswordControllerTest do
  use PjeskiWeb.ConnCase

  use Bamboo.Test

  alias Pjeski.{Repo, Users}

  @valid_attrs %{email: "test@storagedeer.com",
                  name: "Henryk Testowny",
                  password: "secret123",
                  password_confirmation: "secret123",
                  locale: "pl",
                  subscription: %{
                    name: "Test",
                    email: "test@example.org"
                  }}

  def user_fixture do
    {:ok, user} = Users.create_user(@valid_attrs)

    user
  end


  describe "new" do
    test "[guest] GET /reset-password/new", %{guest_conn: conn} do
      conn = get(conn, "/reset-password/new")
      assert html_response(conn, 200) =~ "Zresetuj hasło"
    end
  end

  describe "edit" do
    test "[guest] GET /reset-password/edit"
  end

  describe "create" do
    test "[guest] [valid attrs] POST /reset-password", %{guest_conn: conn} do
      user = user_fixture()

      conn = post(conn, "/reset-password", user: %{email: @valid_attrs.email})

      redirected_path = redirected_to(conn, 302)
      assert "/session/new" = redirected_path
      conn = get(recycle(conn), redirected_path)

      assert html_response(conn, 200) =~ "Wysłano adres e-mail"

      assert_email_delivered_with(
        to: [nil: @valid_attrs.email], # TODO: czy to w ogole dziala? :O
        # text_body: ~r/TODO: TOKEN/
      )
    end

    test "[guest] [invalid attrs - non-existing email] POST /reset-password", %{guest_conn: conn} do
      user = user_fixture()

      conn = post(conn, "/reset-password", user: %{email: "non-existing-email@storagedeer.com"})

      redirected_path = redirected_to(conn, 302)
      assert "/session/new" = redirected_path
      conn = get(recycle(conn), redirected_path)

      assert html_response(conn, 200) =~ "Wysłano adres e-mail"

      assert_no_emails_delivered()
    end

    test "[guest] [invalid attrs - empty email] POST /reset-password", %{guest_conn: conn} do
      user = user_fixture()

      conn = post(conn, "/reset-password", user: %{email: ""})

      redirected_path = redirected_to(conn, 302)
      assert "/session/new" = redirected_path
      conn = get(recycle(conn), redirected_path)

      assert html_response(conn, 200) =~ "Wysłano adres e-mail"

      assert_no_emails_delivered()
    end
  end

  describe "update" do
    test "[guest] [valid attrs] POST /reset-password"
    test "[guest] [invalid attrs] POST /reset-password"
  end
end
