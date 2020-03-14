defmodule PjeskiWeb.ResetPasswordControllerTest do
  use PjeskiWeb.ConnCase

  use Bamboo.Test

  alias Pjeski.{Repo, Users, Users.User}

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
    test "[guest] GET /reset-password/edit", %{guest_conn: conn} do
      user_fixture()

      {:ok, %{token: token}, conn} = conn |> PowResetPassword.Plug.create_reset_token(%{"email" => @valid_attrs.email})

      conn = get(conn, "/reset-password/#{token}/edit")

      assert html_response(conn, 200) =~ "Nowe hasło"
    end
  end

  describe "create" do
    test "[guest] [valid attrs] POST /reset-password", %{guest_conn: conn} do
      user_fixture()

      conn = post(conn, "/reset-password", user: %{email: @valid_attrs.email})

      redirected_path = redirected_to(conn, 302)
      assert "/session/new" = redirected_path
      conn = get(recycle(conn), redirected_path)

      assert html_response(conn, 200) =~ "Wysłano adres e-mail"

      assert_email_delivered_with(
        to: [nil: @valid_attrs.email] # TODO: czy to w ogole dziala? :O
        # text_body: ~r/TODO: TOKEN/
      )
    end

    test "[guest] [invalid attrs - non-existing email] POST /reset-password", %{guest_conn: conn} do
      user_fixture()

      conn = post(conn, "/reset-password", user: %{email: "non-existing-email@storagedeer.com"})

      redirected_path = redirected_to(conn, 302)
      assert "/session/new" = redirected_path
      conn = get(recycle(conn), redirected_path)

      assert html_response(conn, 200) =~ "Wysłano adres e-mail"

      assert_no_emails_delivered()
    end

    test "[guest] [invalid attrs - empty email] POST /reset-password", %{guest_conn: conn} do
      user_fixture()

      conn = post(conn, "/reset-password", user: %{email: ""})

      redirected_path = redirected_to(conn, 302)
      assert "/session/new" = redirected_path
      conn = get(recycle(conn), redirected_path)

      assert html_response(conn, 200) =~ "Wysłano adres e-mail"

      assert_no_emails_delivered()
    end
  end

  describe "update" do
    test "[guest] [valid attrs] POST /reset-password", %{guest_conn: conn} do
      user = user_fixture()

      {:ok, %{token: token}, conn} = conn |> PowResetPassword.Plug.create_reset_token(%{"email" => @valid_attrs.email})

      user_params = %{password: "secret999", password_confirmation: "secret999"}
      conn = put(conn, "/reset-password/#{token}", %{user: user_params})

      # Make sure password changed
      {:ok, reloaded_user_password_hash} = Repo.get(User, user.id) |> Map.fetch(:password_hash)
      refute user.password_hash == reloaded_user_password_hash

      redirected_path = redirected_to(conn, 302)
      assert "/session/new" = redirected_path
      conn = get(recycle(conn), redirected_path)

      assert html_response(conn, 200) =~ "Hasło zmienione"
    end

    test "[guest] [invalid attrs: no password_confirmation] POST /reset-password", %{guest_conn: conn} do
      user = user_fixture()

      {:ok, %{token: token}, conn} = conn |> PowResetPassword.Plug.create_reset_token(%{"email" => @valid_attrs.email})

      # Make sure password didn't change
      {:ok, reloaded_user_password_hash} = Repo.get(User, user.id) |> Map.fetch(:password_hash)
      assert user.password_hash == reloaded_user_password_hash

      user_params = %{password: "secret999"}
      conn = put(conn, "/reset-password/#{token}", %{user: user_params})

      assert html_response(conn, 200) =~ "Coś poszło nie tak. Sprawdź błędy poniżej"
    end
  end
end
