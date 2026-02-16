defmodule DeerStorageWeb.ResetPasswordControllerTest do
  use DeerStorageWeb.ConnCase
  use Bamboo.Test

  alias DeerStorage.{Repo, Users, Users.User}
  alias DeerStorage.FeatureFlags

  @valid_attrs %{
    email: "test@storagedeer.com",
    name: "Henryk Testowny",
    password: "secret123",
    password_confirmation: "secret123",
    locale: "pl",
    last_used_subscription: %{
      name: "Test",
      email: "test@example.org"
    }
  }

  def user_fixture do
    {:ok, user} = Users.create_user(@valid_attrs)

    Map.put(user, :password, @valid_attrs.password)
  end

  describe "new" do
    test "[guest] GET /reset-password/new", %{conn: conn} do
      conn = get(conn, "/reset-password/new")

      if FeatureFlags.mailing_enabled?() do
        assert html_response(conn, 200) =~ "Reset password"
      else
        assert text_response(conn, 200) =~ "Feature is disabled"
      end
    end
  end

  describe "edit" do
    test "[guest] GET /reset-password/edit", %{conn: conn} do
      if !FeatureFlags.mailing_enabled?() do
        # Skip when mailing is disabled
        assert true
      else
        user_fixture()

        {:ok, %{token: token}, conn} =
          conn |> PowResetPassword.Plug.create_reset_token(%{"email" => @valid_attrs.email})

        conn = get(conn, "/reset-password/#{token}/edit")

        assert html_response(conn, 200) =~ "New password"
      end
    end
  end

  describe "create" do
    test "[guest] [valid attrs] POST /reset-password", %{conn: conn} do
      if !FeatureFlags.mailing_enabled?() do
        # Skip when mailing is disabled
        assert true
      else
        user_fixture()

        conn = post(conn, "/reset-password", user: %{email: @valid_attrs.email})

        redirected_path = redirected_to(conn, 302)
        assert "/session/new" = redirected_path
        conn = get(recycle(conn), redirected_path)

        assert html_response(conn, 200) =~ "Email has been sent"

        assert_email_delivered_with(
          # TODO: czy to w ogole dziala? :O
          to: [nil: @valid_attrs.email]
          # text_body: ~r/TODO: TOKEN/
        )
      end
    end

    test "[guest] [invalid attrs - non-existing email] POST /reset-password", %{conn: conn} do
      if !FeatureFlags.mailing_enabled?() do
        # Skip when mailing is disabled
        assert true
      else
        user_fixture()

        conn = post(conn, "/reset-password", user: %{email: "non-existing-email@storagedeer.com"})

        redirected_path = redirected_to(conn, 302)
        assert "/session/new" = redirected_path
        conn = get(recycle(conn), redirected_path)

        assert html_response(conn, 200) =~ "Email has been sent"

        assert_no_emails_delivered()
      end
    end

    test "[guest] [invalid attrs - empty email] POST /reset-password", %{conn: conn} do
      if !FeatureFlags.mailing_enabled?() do
        # Skip when mailing is disabled
        assert true
      else
        user_fixture()

        conn = post(conn, "/reset-password", user: %{email: ""})

        redirected_path = redirected_to(conn, 302)
        assert "/session/new" = redirected_path
        conn = get(recycle(conn), redirected_path)

        assert html_response(conn, 200) =~ "Email has been sent"

        assert_no_emails_delivered()
      end
    end
  end

  describe "update" do
    test "[guest] [valid attrs] POST /reset-password", %{conn: conn} do
      if !FeatureFlags.mailing_enabled?() do
        # Skip when mailing is disabled
        assert true
      else
        user = user_fixture()

        {:ok, %{token: token}, conn} =
          conn |> PowResetPassword.Plug.create_reset_token(%{"email" => @valid_attrs.email})

        user_params = %{password: "secret999", password_confirmation: "secret999"}
        conn = put(conn, "/reset-password/#{token}", %{user: user_params})

        # Make sure password changed
        {:ok, reloaded_user_password_hash} = Repo.get(User, user.id) |> Map.fetch(:password_hash)
        refute user.password_hash == reloaded_user_password_hash

        redirected_path = redirected_to(conn, 302)
        assert "/session/new" = redirected_path
        conn = get(recycle(conn), redirected_path)

        assert html_response(conn, 200) =~ "Password has been changed"
      end
    end

    test "[guest] [invalid attrs: no password_confirmation] POST /reset-password", %{conn: conn} do
      if !FeatureFlags.mailing_enabled?() do
        # Skip when mailing is disabled
        assert true
      else
        user = user_fixture()

        {:ok, %{token: token}, conn} =
          conn |> PowResetPassword.Plug.create_reset_token(%{"email" => @valid_attrs.email})

        # Make sure password didn't change
        {:ok, reloaded_user_password_hash} = Repo.get(User, user.id) |> Map.fetch(:password_hash)
        assert user.password_hash == reloaded_user_password_hash

        user_params = %{password: "secret999"}
        conn = put(conn, "/reset-password/#{token}", %{user: user_params})

        assert html_response(conn, 200) =~ "Oops, something went wrong"
      end
    end
  end
end
