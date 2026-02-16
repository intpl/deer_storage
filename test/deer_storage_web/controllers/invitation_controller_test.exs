defmodule DeerStorageWeb.InvitationControllerTest do
  use DeerStorageWeb.ConnCase
  use Bamboo.Test

  import DeerStorage.Fixtures
  import DeerStorage.Test.SessionHelpers, only: [assign_user_to_session: 2]
  alias DeerStorage.{Repo, Users.User}
  alias DeerStorage.FeatureFlags

  def invite_user(conn, inviting_user, email \\ "invited_user@storagedeer.com") do
    assign_user_to_session(conn, inviting_user) |> post("/invitation", user: %{email: email})

    Repo.get_by!(User, email: email) |> Repo.preload(:available_subscriptions)
  end

  def valid_update_params_for(email \\ Faker.Internet.safe_email()) do
    %{
      email: email,
      name: Faker.Person.name(),
      password: "secret123",
      password_confirmation: "secret123"
    }
  end

  describe "new" do
    test "[user] [logged in] GET /invitation", %{conn: conn} do
      user =
        create_valid_user_with_subscription(random_user_attrs(), random_subscription_attrs(), %{
          permission_to_manage_users: true
        })

      conn = assign_user_to_session(conn, user) |> get("/invitation/new")

      assert html_response(conn, 200) =~ "Zaproś użytkownika"
    end
  end

  describe "create" do
    test "[user] [valid params - new email] POST /invitation", %{conn: conn} do
      if FeatureFlags.mailing_enabled?() do
        user =
          create_valid_user_with_subscription(
            %{random_user_attrs() | email_confirmed_at: nil},
            random_subscription_attrs(),
            %{
              permission_to_manage_users: true
            }
          )

        conn =
          assign_user_to_session(conn, user)
          |> post("/invitation", user: %{email: "invited_user@storagedeer.com"})

        assert_email_delivered_with(to: [nil: "invited_user@storagedeer.com"])
        assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Invitation e-mail sent"
      else
        assert true
      end
    end

    test "[user] [valid params - email already exists - add to another subscription] POST /invitation",
         %{conn: conn} do
      user =
        create_valid_user_with_subscription(random_user_attrs(), random_subscription_attrs(), %{
          permission_to_manage_users: true
        })

      user2 = create_valid_user_with_subscription() |> Repo.preload(:available_subscriptions)

      assert length(user2.available_subscriptions) == 1

      assign_user_to_session(conn, user)
      |> post("/invitation", user: %{email: user2.email})

      assert_no_emails_delivered()

      reloaded_user2 = Repo.get(User, user2.id) |> Repo.preload(:available_subscriptions)

      assert user2.last_used_subscription_id == reloaded_user2.last_used_subscription_id
      assert length(reloaded_user2.available_subscriptions) == 2

      # TODO: add available_subscriptions_ids
    end

    test "[user] [invalid params] POST /invitation", %{conn: conn} do
      user =
        create_valid_user_with_subscription(random_user_attrs(), random_subscription_attrs(), %{
          permission_to_manage_users: true
        })

      conn = assign_user_to_session(conn, user)

      post(conn, "/invitation", user: %{email: "invalid_email.gmail"})

      assert_no_emails_delivered()
    end
  end

  describe "edit" do
    test "[guest] [valid params] GET /invitation/:id/edit", %{conn: conn} do
      user =
        create_valid_user_with_subscription(random_user_attrs(), random_subscription_attrs(), %{
          permission_to_manage_users: true
        })

      new_user = invite_user(conn, user) |> Repo.preload(:available_subscriptions)

      assert new_user.invited_by_id == user.id

      assert new_user.available_subscriptions |> Enum.map(fn sub -> sub.id end) == [
               user.last_used_subscription_id
             ]

      assert new_user.password_hash == nil

      conn = get(conn, "/invitation/#{sign_token(conn, new_user.invitation_token)}/edit")
      assert html_response(conn, 200) =~ "You have been invited to join DeerStorage team!"
    end

    # test "[guest] [invalid params] GET /invitation/:id/edit", %{conn: conn} do
    #   # FIXME ** (Plug.Conn.AlreadySentError) the response was already sent
    #   conn = get(conn, "/invitation/invalid/edit")
    #   IO.inspect Phoenix.Controller.get_flash(conn)

    #   assert html_response(conn, 200) =~ "Invalid token"
    # end
  end

  describe "update" do
    test "[guest] [valid params] PUT /invitation", %{conn: conn} do
      user =
        create_valid_user_with_subscription(random_user_attrs(), random_subscription_attrs(), %{
          permission_to_manage_users: true
        })

      new_user = invite_user(conn, user)

      conn =
        put(conn, "/invitation/#{sign_token(conn, new_user.invitation_token)}", %{
          user: valid_update_params_for(new_user.email)
        })

      # TODO change this to something like "Welcome"
      assert Phoenix.Controller.get_flash(conn, :info) == "User has been created"
    end

    test "[guest] [invalid params - invalid e-mail] PUT /invitation", %{conn: conn} do
      user =
        create_valid_user_with_subscription(random_user_attrs(), random_subscription_attrs(), %{
          permission_to_manage_users: true
        })

      new_user = invite_user(conn, user)

      conn =
        put(conn, "/invitation/#{sign_token(conn, new_user.invitation_token)}", %{
          user: valid_update_params_for("invalid")
        })

      # TODO: capitalized?
      assert html_response(conn, 200) =~ "has invalid format"
    end

    test "[guest] [invalid params - different e-mail] PUT /invitation", %{conn: conn} do
      user =
        create_valid_user_with_subscription(random_user_attrs(), random_subscription_attrs(), %{
          permission_to_manage_users: true
        })

      new_user = invite_user(conn, user)

      conn =
        put(conn, "/invitation/#{sign_token(conn, new_user.invitation_token)}", %{
          user: valid_update_params_for("something_entirely_different@storagedeer.com")
        })

      # TODO change this to something like "Welcome"
      assert Phoenix.Controller.get_flash(conn, :info) == "User has been created"

      assert Repo.get(User, new_user.id).email == new_user.email
    end

    test "[guest] [invalid params - different subscription id] PUT /invitation", %{conn: conn} do
      user =
        create_valid_user_with_subscription(random_user_attrs(), random_subscription_attrs(), %{
          permission_to_manage_users: true
        })

      new_user = invite_user(conn, user)

      params = %{
        user:
          valid_update_params_for(new_user.email) |> Map.merge(%{last_used_subscription_id: 1337})
      }

      conn = put(conn, "/invitation/#{sign_token(conn, new_user.invitation_token)}", params)

      # TODO change this to something like "Welcome"
      assert Phoenix.Controller.get_flash(conn, :info) == "User has been created"

      assert Repo.get(User, new_user.id).last_used_subscription_id ==
               new_user.last_used_subscription_id
    end

    test "[guest] [invalid params - subscription nested attrs] PUT /invitation", %{conn: conn} do
      user =
        create_valid_user_with_subscription(random_user_attrs(), random_subscription_attrs(), %{
          permission_to_manage_users: true
        })

      new_user = invite_user(conn, user)

      params = %{
        user:
          valid_update_params_for(new_user.email)
          |> Map.merge(%{last_used_subscription: %{name: "Hacked", email: "hacked"}})
      }

      put(conn, "/invitation/#{sign_token(conn, new_user.invitation_token)}", params)

      reloaded_user = Repo.get!(User, user.id) |> Repo.preload(:available_subscriptions)

      refute List.first(reloaded_user.available_subscriptions).name == "Hacked"
    end

    test "[guest] [invalid params - unpermitted params] PUT /invitation", %{conn: conn} do
      user =
        create_valid_user_with_subscription(random_user_attrs(), random_subscription_attrs(), %{
          permission_to_manage_users: true
        })

      new_user = invite_user(conn, user)
      params = %{user: valid_update_params_for(new_user.email) |> Map.merge(%{role: "admin"})}

      conn = put(conn, "/invitation/#{sign_token(conn, new_user.invitation_token)}", params)

      # TODO change this to something like "Welcome"
      assert Phoenix.Controller.get_flash(conn, :info) == "User has been created"

      assert Repo.get(User, new_user.id).role == "user"
    end
  end

  defp sign_token(conn, token) do
    conn
    |> PowInvitation.Plug.sign_invitation_token(%{invitation_token: token})
  end
end
