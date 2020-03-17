defmodule PjeskiWeb.InvitationControllerTest do
  use PjeskiWeb.ConnCase
  use Bamboo.Test

  import Pjeski.Fixtures

  describe "new" do
    test "[user] [logged in] GET /invitation", %{user_conn: conn} do
      conn = get(conn, "/invitation/new")
      assert html_response(conn, 200) =~ "Zaproś użytkownika do StorageDeer!"
    end
  end

  describe "create" do
    # TODO: somehow redirects to /session/new, therefore checking flash only

    test "[user] [valid params - new email] POST /invitation", %{guest_conn: guest_conn} do
      user = create_valid_user_with_subscription()

      conn = Pow.Plug.assign_current_user(guest_conn, user, [])
      |> post("/invitation", user: %{email: "invited_user@storagedeer.com"})

      assert_email_delivered_with(
        to: [nil: "invited_user@storagedeer.com"] # TODO: czy to w ogole dziala? :O
        # text_body: ~r/TODO: TOKEN/
      )

      assert Phoenix.Controller.get_flash(conn, :info) == "Wysłano e-mail potwierdzający"
    end

    test "[user] [valid params - email already exists] POST /invitation"

    test "[user] [invalid params] POST /invitation", %{guest_conn: guest_conn} do
      user = create_valid_user_with_subscription()

      Pow.Plug.assign_current_user(guest_conn, user, [])
      |> post("/invitation", user: %{email: "invalid_email.gmail"})

      assert_no_emails_delivered()
    end
  end

  describe "edit" do
    test "[guest] [valid params] GET /invitation"
    test "[guest] [invalid params] GET /invitation"
  end

  describe "update" do
    test "[guest] [valid params] GET /invitation"
    test "[guest] [invalid params] GET /invitation"
  end
end
