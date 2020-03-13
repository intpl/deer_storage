defmodule PjeskiWeb.RegistrationControllerTest do
  use PjeskiWeb.ConnCase

  use Bamboo.Test

  alias Pjeski.{Repo, Users, Users.User, Subscriptions}

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
    test "[guest] GET /registration/new", %{guest_conn: conn} do
      conn = get(conn, "/registration/new")
      assert html_response(conn, 200) =~ "Zarejestruj się w StorageDeer"
    end
  end

  describe "edit" do
    test "[user] GET /registration/edit", %{user_conn: conn} do
      conn = get(conn, "/registration/edit")
      assert html_response(conn, 200) =~ "Edytuj swoje konto w StorageDeer"
    end
  end

  describe "create" do
    test "[guest] [valid attrs] POST /registration", %{guest_conn: conn} do
      conn = post(conn, "/registration", user: @valid_attrs)
      redirected_path = redirected_to(conn, 302)
      assert "/session/new" = redirected_path
      conn = get(recycle(conn), redirected_path)

      assert html_response(conn, 200) =~ "Musisz potwierdzić swój adres e-mail przed pierwszym zalogowaniem"
      assert Subscriptions.total_count == 1
      assert Users.total_count == 1

      {:ok, email_confirmation_token} = Users.last_user |> Map.fetch(:email_confirmation_token)

      assert_email_delivered_with(
        to: [nil: @valid_attrs.email], # TODO: czy to w ogole dziala? :O
        text_body: ~r/#{email_confirmation_token}/
      )
    end

    test "[guest] [invalid attrs] POST /registration", %{guest_conn: conn} do
      conn = post(conn, "/registration", user: %{})

      assert html_response(conn, 200) =~ "Coś poszło nie tak. Sprawdź błędy poniżej"
    end
  end

  describe "update" do
    test "[user] PUT /registration - changes name", %{guest_conn: guest_conn} do
      user = user_fixture()
      new_name = "New example name"

      conn = Pow.Plug.assign_current_user(guest_conn, user, [])
      |> put("/registration", user: @valid_attrs |> Map.merge(%{name: new_name, current_password: "secret123"}))

      assert html_response(conn, 200) =~ "Konto zaktualizowane"

      {:ok, reloaded_user} = Repo.get(User, user.id) |> Map.fetch(:name)
      assert reloaded_user == new_name
    end

    test "[user] PUT /registration - renders error when missing current_password", %{guest_conn: guest_conn} do
      user = user_fixture()
      new_name = "New example name"

      conn = Pow.Plug.assign_current_user(guest_conn, user, [])
      |> put("/registration", user: @valid_attrs |> Map.merge(%{name: new_name}))

      assert html_response(conn, 200) =~ "Coś poszło nie tak. Sprawdź błędy poniżej"

      {:ok, reloaded_user} = Repo.get(User, user.id) |> Map.fetch(:name)
      refute reloaded_user == new_name
    end

    test "[user] PUT /registration - changing email sends e-mail", %{guest_conn: guest_conn} do
      user = user_fixture()
      new_email = "test_new@storagedeer.com"

      conn = Pow.Plug.assign_current_user(guest_conn, user, [])
      |> put("/registration", user: @valid_attrs |> Map.merge(%{email: new_email, current_password: "secret123"}))

      assert html_response(conn, 200) =~ "Wysłano e-mail w celu potwierdzenia na adres: <span>#{new_email}</span>"

      {:ok, reloaded_user} = Repo.get(User, user.id) |> Map.fetch(:email)
      refute reloaded_user == new_email

      {:ok, email_confirmation_token} = Users.last_user |> Map.fetch(:email_confirmation_token)
      assert_email_delivered_with(
        to: [nil: new_email], # TODO: czy to w ogole dziala? :O
        text_body: ~r/#{email_confirmation_token}/
      )
    end
  end
end
