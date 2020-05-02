defmodule PjeskiWeb.InvitationControllerTest do
  use PjeskiWeb.ConnCase
  use Bamboo.Test

  import Pjeski.Fixtures
  import Pjeski.Test.SessionHelpers, only: [assign_user_to_session: 2]
  alias Pjeski.{Repo, Users.User, Subscriptions.Subscription}

  def invite_user(conn, inviting_user, email \\ "invited_user@storagedeer.com") do
      {:ok, new_user, _conn} = assign_user_to_session(conn, inviting_user)
      |> PowInvitation.Plug.create_user(%{email: email})

      new_user
  end

  def valid_update_params_for(email \\ Faker.Internet.safe_email()) do
    %{
         email: email,
         name: Faker.Name.name(),
         password: "secret123",
         password_confirmation: "secret123"
    }
  end

  describe "new" do
    test "[user] [logged in] GET /invitation", %{guest_conn: guest_conn} do
      user = create_valid_user_with_subscription()
      conn = assign_user_to_session(guest_conn, user) |> get("/invitation/new")

      assert html_response(conn, 200) =~ "Zaproś użytkownika do StorageDeer!"
    end
  end

  describe "create" do
    # TODO: somehow redirects to /session/new, therefore checking flash only

    test "[user] [valid params - new email] POST /invitation", %{guest_conn: guest_conn} do
      user = create_valid_user_with_subscription()

      for _ <- [1,2] do # ensure resends
        conn = assign_user_to_session(guest_conn, user)
        |> post("/invitation", user: %{email: "invited_user@storagedeer.com"})

        assert_email_delivered_with(
          to: [nil: "invited_user@storagedeer.com"] # TODO: czy to w ogole dziala? :O
          # text_body: ~r/TODO: TOKEN/
        )

        assert Phoenix.Controller.get_flash(conn, :info) == "Wysłano e-mail potwierdzający"
       end
    end

    test "[user] [valid params - email already exists - add to another subscription] POST /invitation", %{guest_conn: guest_conn} do
      user = create_valid_user_with_subscription()
      user2 = create_valid_user_with_subscription() |> Repo.preload(:available_subscriptions)

      assert length(user2.available_subscriptions) == 1

      assign_user_to_session(guest_conn, user)
      |> post("/invitation", user: %{email: user2.email})

      assert_no_emails_delivered()

      reloaded_user2 = Repo.get(User, user2.id) |> Repo.preload(:available_subscriptions)

      assert user2.subscription_id == reloaded_user2.subscription_id
      assert length(reloaded_user2.available_subscriptions) == 2

      # TODO: add available_subscriptions_ids
    end

    test "[user] [invalid params] POST /invitation", %{guest_conn: guest_conn} do
      user = create_valid_user_with_subscription()
      conn = assign_user_to_session(guest_conn, user)

      post(conn, "/invitation", user: %{email: "invalid_email.gmail"})

      assert_no_emails_delivered()
    end
  end

  describe "edit" do
    test "[guest] [valid params] GET /invitation/:id/edit", %{guest_conn: guest_conn} do
      user = create_valid_user_with_subscription()
      new_user = invite_user(guest_conn, user)

      assert new_user.invited_by_id == user.id
      assert new_user.subscription_id == user.subscription_id
      assert new_user.password_hash == nil

      conn = get(guest_conn, "/invitation/#{sign_token(guest_conn, new_user.invitation_token)}/edit")
      assert html_response(conn, 200) =~ "Zostałeś zaproszony do subskrypcji w StorageDeer!"
    end

    # test "[guest] [invalid params] GET /invitation/:id/edit", %{guest_conn: guest_conn} do
    #   # FIXME ** (Plug.Conn.AlreadySentError) the response was already sent
    #   conn = get(guest_conn, "/invitation/invalid/edit")
    #   IO.inspect Phoenix.Controller.get_flash(conn)

    #   assert html_response(conn, 200) =~ "Nieprawidłowy token"
    # end
  end

  describe "update" do
    test "[guest] [valid params] PUT /invitation", %{guest_conn: guest_conn} do
      user = create_valid_user_with_subscription()
      new_user = invite_user(guest_conn, user)

      conn = put(guest_conn, "/invitation/#{sign_token(guest_conn, new_user.invitation_token)}", %{user: valid_update_params_for(new_user.email)})

      assert Phoenix.Controller.get_flash(conn, :info) == "Użytkownik utworzony" # TODO change this to something like "Welcome"
    end

    test "[guest] [invalid params - invalid e-mail] PUT /invitation", %{guest_conn: guest_conn} do
      user = create_valid_user_with_subscription()
      new_user = invite_user(guest_conn, user)

      conn = put(guest_conn, "/invitation/#{sign_token(guest_conn, new_user.invitation_token)}", %{user: valid_update_params_for("invalid")})

      assert html_response(conn, 200) =~ "ma niepoprawny format" # TODO: capitalized?
    end

    test "[guest] [invalid params - different e-mail] PUT /invitation", %{guest_conn: guest_conn} do
      user = create_valid_user_with_subscription()
      new_user = invite_user(guest_conn, user)

      conn = put(guest_conn, "/invitation/#{sign_token(guest_conn, new_user.invitation_token)}", %{user: valid_update_params_for("something_entirely_different@storagedeer.com")})

      assert Phoenix.Controller.get_flash(conn, :info) == "Użytkownik utworzony" # TODO change this to something like "Welcome"

      assert Repo.get(User, new_user.id).email == new_user.email
    end

    test "[guest] [invalid params - different subscription id] PUT /invitation", %{guest_conn: guest_conn} do
      user = create_valid_user_with_subscription()
      new_user = invite_user(guest_conn, user)
      params = %{user: valid_update_params_for(new_user.email) |> Map.merge(%{subscription_id: 1337})}

      conn = put(guest_conn, "/invitation/#{sign_token(guest_conn, new_user.invitation_token)}", params)

      assert Phoenix.Controller.get_flash(conn, :info) == "Użytkownik utworzony" # TODO change this to something like "Welcome"

      assert Repo.get(User, new_user.id).subscription_id == new_user.subscription_id
    end

    test "[guest] [invalid params - subscription nested attrs] PUT /invitation", %{guest_conn: guest_conn} do
      user = create_valid_user_with_subscription()
      new_user = invite_user(guest_conn, user)
      params = %{user: valid_update_params_for(new_user.email) |> Map.merge(%{subscription: %{name: "Hacked", email: "hacked"}})}

      put(guest_conn, "/invitation/#{sign_token(guest_conn, new_user.invitation_token)}", params)

      refute Repo.get(Subscription, new_user.subscription_id).name == "Hacked"
    end

    test "[guest] [invalid params - unpermitted params] PUT /invitation", %{guest_conn: guest_conn} do
      user = create_valid_user_with_subscription()
      new_user = invite_user(guest_conn, user)
      params = %{user: valid_update_params_for(new_user.email) |> Map.merge(%{role: "admin"})}

      conn = put(guest_conn, "/invitation/#{sign_token(guest_conn, new_user.invitation_token)}", params)

      assert Phoenix.Controller.get_flash(conn, :info) == "Użytkownik utworzony" # TODO change this to something like "Welcome"

      assert Repo.get(User, new_user.id).role == "user"
    end
  end

  defp sign_token(conn, token) do
    conn
    |> PowInvitation.Plug.sign_invitation_token(%{invitation_token: token})
  end
end
