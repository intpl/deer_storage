defmodule PjeskiWeb.RegistrationControllerTest do
  use PjeskiWeb.ConnCase
  use Bamboo.Test

  alias Pjeski.{Repo, Users, Users.User, Subscriptions, UserAvailableSubscriptionLinks.UserAvailableSubscriptionLink}

  import Pjeski.Fixtures
  import Pjeski.Test.SessionHelpers, only: [assign_user_to_session: 2]

  @valid_attrs %{email: "test@storagedeer.com",
                  name: "Henryk Testowny",
                  password: "secret123",
                  password_confirmation: "secret123",
                  locale: "pl",
                  last_used_subscription: %{
                    name: "Test",
                    email: "test@example.org"
                  }}

  def user_fixture do
    {:ok, user} = Users.create_user(@valid_attrs)

    user
  end

  def admin_fixture do
    {:ok, admin} = Users.admin_create_user(@valid_attrs |> Map.merge(%{role: "admin", subscription: nil}))

    admin
  end

  def current_subscription_id_from_conn(conn), do: conn.private.plug_session["current_subscription_id"]

  describe "new" do
    test "[guest] GET /registration/new", %{conn: conn} do
      conn = get(conn, "/registration/new")
      assert html_response(conn, 200) =~ "Zarejestruj się w StorageDeer"
    end
  end

  describe "edit" do
    test "[user with subscription] GET /registration/edit", %{conn: conn} do
      user = create_valid_user_with_subscription(@valid_attrs)
      conn = assign_user_to_session(conn, user)

      conn = get(conn, "/registration/edit")
      assert html_response(conn, 200) =~ "Edytuj swoje konto w StorageDeer"
    end

    test "[user without subscription] GET /registration/edit", %{conn: conn} do
      # TODO workaround, but it needs to be changed
      {:ok, user} = @valid_attrs |> Map.merge(%{last_used_subscription: nil}) |> Users.admin_create_user
      user = user |> Repo.preload(:available_subscriptions)

      conn = assign_user_to_session(conn, user)

      conn = get(conn, "/registration/edit")
      assert html_response(conn, 200) =~ "Edytuj swoje konto w StorageDeer"
    end
  end

  describe "create" do
    test "[guest] [valid attrs] POST /registration", %{conn: conn} do
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

    test "[guest] [invalid attrs] POST /registration", %{conn: conn} do
      conn = post(conn, "/registration", user: %{})

      assert html_response(conn, 200) =~ "Coś poszło nie tak. Sprawdź błędy poniżej"
    end
  end

  describe "update" do
    test "[user] PUT /registration - changes name", %{conn: conn} do
      user = create_valid_user_with_subscription(@valid_attrs)
      new_name = "New example name"

      conn = assign_user_to_session(conn, user)
      |> put("/registration", user: @valid_attrs |> Map.merge(%{name: new_name, current_password: "secret123"}))

      assert html_response(conn, 200) =~ "Konto zaktualizowane"

      {:ok, reloaded_user_name} = Repo.get(User, user.id) |> Map.fetch(:name)
      assert reloaded_user_name == new_name
    end

    test "[user] PUT /registration - renders error when missing current_password", %{conn: conn} do
      user = create_valid_user_with_subscription(@valid_attrs)
      new_name = "New example name"

      conn = assign_user_to_session(conn, user)
      |> put("/registration", user: @valid_attrs |> Map.merge(%{name: new_name}))

      assert html_response(conn, 200) =~ "Coś poszło nie tak. Sprawdź błędy poniżej"

      {:ok, reloaded_user_name} = Repo.get(User, user.id) |> Map.fetch(:name)
      refute reloaded_user_name == new_name
    end

    test "[user] PUT /registration - changing email sends e-mail", %{conn: conn} do
      user = create_valid_user_with_subscription(@valid_attrs)
      new_email = "test_new@storagedeer.com"

      conn = assign_user_to_session(conn, user)
      |> put("/registration", user: @valid_attrs |> Map.merge(%{email: new_email, current_password: "secret123"}))

      assert html_response(conn, 200) =~ "Wysłano e-mail w celu potwierdzenia na adres: <span>#{new_email}</span>"

      {:ok, reloaded_user_email} = Repo.get(User, user.id) |> Map.fetch(:email)
      refute reloaded_user_email == new_email

      {:ok, email_confirmation_token} = Users.last_user |> Map.fetch(:email_confirmation_token)
      assert_email_delivered_with(
        to: [nil: new_email], # TODO: czy to w ogole dziala? :O
        text_body: ~r/#{email_confirmation_token}/
      )
    end
  end

  describe "switch_subscription_id" do
    test "[user - available subscription] PUT /switch_subscription_id - changes subscription_id", %{conn: conn} do
      user = create_valid_user_with_subscription(@valid_attrs)
      {:ok, new_subscription} = Subscriptions.create_subscription(%{name: "New Subscription"})
      Repo.insert! %UserAvailableSubscriptionLink{user_id: user.id, subscription_id: new_subscription.id}

      conn = post(conn, "/session", user: %{email: @valid_attrs.email, password: @valid_attrs.password})

      conn = conn |> put("/registration/switch_subscription_id/#{new_subscription.id}")

      redirected_path = redirected_to(conn, 302)
      assert Phoenix.Controller.get_flash(conn) == %{"info" => "Zmieniono obecną subskrypcję"}
      assert "/registration/edit" = redirected_path

      assert Repo.get!(User, user.id).last_used_subscription_id == new_subscription.id
      assert new_subscription.id == current_subscription_id_from_conn(conn)
    end

    test "[user - not available subscription] PUT /switch_subscription_id - does not change subscription_id", %{conn: conn} do
      user = create_valid_user_with_subscription(@valid_attrs)
      original_subscription_id = user.last_used_subscription_id
      {:ok, new_subscription} = Subscriptions.create_subscription(%{name: "New Subscription"})

      conn = post(conn, "/session", user: %{email: @valid_attrs.email, password: @valid_attrs.password})

      assert_raise FunctionClauseError, fn ->
         conn |> put("/registration/switch_subscription_id/#{new_subscription.id}")
      end

      reloaded_user = Repo.get!(User, user.id) |> Repo.preload(:available_subscriptions)

      refute reloaded_user.last_used_subscription_id == new_subscription.id
      assert reloaded_user.available_subscriptions |> Enum.map(fn sub -> sub.id end) == [original_subscription_id]
    end

    test "[user - invalid subscription id] PUT /switch_subscription_id - does not change subscription_id", %{conn: conn} do
      create_valid_user_with_subscription(@valid_attrs)

      conn = post(conn, "/session", user: %{email: @valid_attrs.email, password: @valid_attrs.password})

      assert_raise ArgumentError, fn -> # tries to run String.to_integer, therefore ArgumentError
         conn |> put("/registration/switch_subscription_id/example")
      end
    end

    test "[admin - available subscription] PUT /switch_subscription_id - changes subscription_id", %{conn: conn} do
      user = create_valid_user_with_subscription(@valid_attrs |> Map.merge(%{role: "admin"}))
      {:ok, new_subscription} = Subscriptions.create_subscription(%{name: "New Subscription"})
      Repo.insert! %UserAvailableSubscriptionLink{user_id: user.id, subscription_id: new_subscription.id}

      conn = post(conn, "/session", user: %{email: @valid_attrs.email, password: @valid_attrs.password})

      conn = conn |> put("/registration/switch_subscription_id/#{new_subscription.id}")

      redirected_path = redirected_to(conn, 302)
      assert Phoenix.Controller.get_flash(conn) == %{"info" => "Zmieniono obecną subskrypcję"}
      assert "/registration/edit" = redirected_path

      assert Repo.get!(User, user.id).last_used_subscription_id == new_subscription.id
      assert new_subscription.id == current_subscription_id_from_conn(conn)
    end
  end

  describe "reset_subscription_id" do
    test "[user] PUT /reset_subscription_id - fails", %{conn: conn} do
      user = create_valid_user_with_subscription(@valid_attrs)

      conn = post(conn, "/session", user: %{email: @valid_attrs.email, password: @valid_attrs.password})

      assert_raise Phoenix.ActionClauseError, fn ->
        conn |> put("/registration/reset_subscription_id")
      end

      refute Repo.get!(User, user.id).last_used_subscription_id == nil
    end

    test "[admin] PUT /reset_subscription_id - nilify subscription_id", %{conn: conn} do
      user = create_valid_user_with_subscription(@valid_attrs |> Map.merge(%{role: "admin"}))

      conn = post(conn, "/session", user: %{email: @valid_attrs.email, password: @valid_attrs.password})

      conn = conn |> put("/registration/reset_subscription_id")

      assert Repo.get!(User, user.id).last_used_subscription_id == nil
      assert nil == current_subscription_id_from_conn(conn)
    end
  end
end
