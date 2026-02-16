defmodule DeerStorageWeb.RegistrationControllerTest do
  use DeerStorageWeb.ConnCase
  use Bamboo.Test

  alias DeerStorage.{
    Repo,
    Users,
    Users.User,
    Subscriptions,
    UserAvailableSubscriptionLinks.UserAvailableSubscriptionLink
  }

  import DeerStorage.Fixtures
  import DeerStorage.Test.SessionHelpers, only: [assign_user_to_session: 2, with_captcha: 1]

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

  @valid_attrs_with_captcha Map.merge(@valid_attrs, %{"captcha" => "42"})

  def user_fixture do
    {:ok, user} = Users.create_user(@valid_attrs)

    user
  end

  def admin_fixture do
    {:ok, admin} =
      Users.admin_create_user(@valid_attrs |> Map.merge(%{role: "admin", subscription: nil}))

    admin
  end

  def current_subscription_id_from_conn(conn),
    do: conn.private.plug_session["current_subscription_id"]

  describe "new" do
    test "[guest] GET /registration/new", %{conn: conn} do
      conn = get(conn, "/registration/new")
      assert html_response(conn, 200) =~ "Register to DeerStorage"
    end
  end

  describe "edit" do
    test "[user with subscription] GET /registration/edit", %{conn: conn} do
      user = create_valid_user_with_subscription(@valid_attrs)
      conn = assign_user_to_session(conn, user)

      conn = get(conn, "/registration/edit")
      assert html_response(conn, 200) =~ "Edytuj swoje konto"
    end

    test "[user without subscription] GET /registration/edit", %{conn: conn} do
      # TODO workaround, but it needs to be changed
      {:ok, user} =
        @valid_attrs |> Map.merge(%{last_used_subscription: nil}) |> Users.admin_create_user()

      user = user |> Repo.preload(:available_subscriptions)

      conn = assign_user_to_session(conn, user)

      conn = get(conn, "/registration/edit")
      assert html_response(conn, 200) =~ "Edytuj swoje konto"
    end
  end

  describe "create" do
    test "[guest] [valid attrs] POST /registration", %{conn: conn} do
      # First visit the new page to get the captcha challenge
      conn_get = get(conn, "/registration/new")
      response_body = html_response(conn_get, 200)

      # Extract the captcha question (e.g., "Please add 18 to 15:")
      captcha_question = Regex.run(~r/Please add (\d+) to (\d+):/, response_body)

      captcha_solution =
        case captcha_question do
          [_, a, b] -> String.to_integer(a) + String.to_integer(b)
          # fallback
          _ -> 42
        end

      # Now post with the correct captcha solution
      user_params = Map.put(@valid_attrs_with_captcha, "captcha", to_string(captcha_solution))
      conn = post(conn_get, "/registration", user: user_params)

      redirected_path = redirected_to(conn, 302)
      assert "/session/new" = redirected_path
      conn = get(recycle(conn), redirected_path)

      assert html_response(conn, 200) =~
               "E-mailing is disabled. You must be confirmed by an administrator"

      assert Subscriptions.total_count() == 1
      assert Users.total_count() == 1

      # When emailing is enabled, user would receive confirmation email
      # For now, user is created but needs admin confirmation
      {:ok, user} = Users.last_user() |> Map.fetch(:email)
      assert user == @valid_attrs.email
    end

    test "[guest] [invalid attrs] POST /registration", %{conn: conn} do
      conn = conn |> with_captcha() |> post("/registration", user: %{"captcha" => "wrong_answer"})

      assert html_response(conn, 200) =~ "Invalid answer to math question"
    end
  end

  describe "update" do
    test "[user] PUT /registration - changes name", %{conn: conn} do
      user = create_valid_user_with_subscription(@valid_attrs)
      new_name = "New example name"

      conn =
        assign_user_to_session(conn, user)
        |> put("/registration",
          user: @valid_attrs |> Map.merge(%{name: new_name, current_password: "secret123"})
        )

      assert html_response(conn, 200) =~ "Konto zaktualizowane"

      {:ok, reloaded_user_name} = Repo.get(User, user.id) |> Map.fetch(:name)
      assert reloaded_user_name == new_name
    end

    test "[user] PUT /registration - renders error when missing current_password", %{conn: conn} do
      user = create_valid_user_with_subscription(@valid_attrs)
      new_name = "New example name"

      conn =
        assign_user_to_session(conn, user)
        |> put("/registration", user: @valid_attrs |> Map.merge(%{name: new_name}))

      assert html_response(conn, 200) =~ "Coś poszło nie tak"

      {:ok, reloaded_user_name} = Repo.get(User, user.id) |> Map.fetch(:name)
      refute reloaded_user_name == new_name
    end

    test "[user] PUT /registration - cannot change email without admin", %{conn: conn} do
      user = create_valid_user_with_subscription(@valid_attrs)
      original_email = user.email
      new_email = "test_new@storagedeer.com"

      conn =
        assign_user_to_session(conn, user)
        |> put("/registration",
          user:
            @valid_attrs
            |> Map.merge(%{email: new_email, current_password: @valid_attrs.password})
        )

      # Users cannot change their own email, they need to ask an admin
      assert html_response(conn, 200) =~ "Nie możesz zmienić"

      reloaded_user = Repo.get(User, user.id)
      # Email should remain unchanged
      assert reloaded_user.email == original_email
    end
  end

  describe "switch_subscription_id" do
    test "[user - available subscription] PUT /switch_subscription_id - changes subscription_id",
         %{conn: conn} do
      user = create_valid_user_with_subscription(@valid_attrs)
      {:ok, new_subscription} = Subscriptions.create_subscription(%{name: "New Subscription"})

      Repo.insert!(%UserAvailableSubscriptionLink{
        user_id: user.id,
        subscription_id: new_subscription.id
      })

      conn =
        post(conn, "/session",
          user: %{email: @valid_attrs.email, password: @valid_attrs.password}
        )

      conn = conn |> put("/registration/switch_subscription_id/#{new_subscription.id}")

      redirected_path = redirected_to(conn, 302)
      assert Phoenix.Controller.get_flash(conn) == %{"info" => "Obecna baza danych zmieniona"}
      assert "/registration/edit" = redirected_path

      assert Repo.get!(User, user.id).last_used_subscription_id == new_subscription.id
      assert new_subscription.id == current_subscription_id_from_conn(conn)
    end

    test "[user - not available subscription] PUT /switch_subscription_id - does not change subscription_id",
         %{conn: conn} do
      user = create_valid_user_with_subscription(@valid_attrs)
      original_subscription_id = user.last_used_subscription_id
      {:ok, new_subscription} = Subscriptions.create_subscription(%{name: "New Subscription"})

      conn =
        post(conn, "/session",
          user: %{email: @valid_attrs.email, password: @valid_attrs.password}
        )

      assert_raise FunctionClauseError, fn ->
        conn |> put("/registration/switch_subscription_id/#{new_subscription.id}")
      end

      reloaded_user = Repo.get!(User, user.id) |> Repo.preload(:available_subscriptions)

      refute reloaded_user.last_used_subscription_id == new_subscription.id

      assert reloaded_user.available_subscriptions |> Enum.map(fn sub -> sub.id end) == [
               original_subscription_id
             ]
    end

    test "[user - invalid subscription id] PUT /switch_subscription_id - does not change subscription_id",
         %{conn: conn} do
      create_valid_user_with_subscription(@valid_attrs)

      conn =
        post(conn, "/session",
          user: %{email: @valid_attrs.email, password: @valid_attrs.password}
        )

      # tries to run String.to_integer, therefore ArgumentError
      assert_raise ArgumentError, fn ->
        conn |> put("/registration/switch_subscription_id/example")
      end
    end

    test "[admin - available subscription] PUT /switch_subscription_id - changes subscription_id",
         %{conn: conn} do
      user = create_valid_user_with_subscription(@valid_attrs |> Map.merge(%{role: "admin"}))
      {:ok, new_subscription} = Subscriptions.create_subscription(%{name: "New Subscription"})

      Repo.insert!(%UserAvailableSubscriptionLink{
        user_id: user.id,
        subscription_id: new_subscription.id
      })

      conn =
        post(conn, "/session",
          user: %{email: @valid_attrs.email, password: @valid_attrs.password}
        )

      conn = conn |> put("/registration/switch_subscription_id/#{new_subscription.id}")

      redirected_path = redirected_to(conn, 302)
      assert Phoenix.Controller.get_flash(conn) == %{"info" => "Obecna baza danych zmieniona"}
      assert "/registration/edit" = redirected_path

      assert Repo.get!(User, user.id).last_used_subscription_id == new_subscription.id
      assert new_subscription.id == current_subscription_id_from_conn(conn)
    end
  end

  describe "reset_subscription_id" do
    test "[user] PUT /reset_subscription_id - fails", %{conn: conn} do
      user = create_valid_user_with_subscription(@valid_attrs)

      conn =
        post(conn, "/session",
          user: %{email: @valid_attrs.email, password: @valid_attrs.password}
        )

      assert_raise Phoenix.ActionClauseError, fn ->
        conn |> put("/registration/reset_subscription_id")
      end

      refute Repo.get!(User, user.id).last_used_subscription_id == nil
    end

    test "[admin] PUT /reset_subscription_id - nilify subscription_id", %{conn: conn} do
      user = create_valid_user_with_subscription(@valid_attrs |> Map.merge(%{role: "admin"}))

      conn =
        post(conn, "/session",
          user: %{email: @valid_attrs.email, password: @valid_attrs.password}
        )

      conn = conn |> put("/registration/reset_subscription_id")

      assert Repo.get!(User, user.id).last_used_subscription_id == nil
      assert nil == current_subscription_id_from_conn(conn)
    end
  end
end
