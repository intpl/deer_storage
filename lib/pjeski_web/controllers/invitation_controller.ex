defmodule PjeskiWeb.InvitationController do
  use PjeskiWeb, :controller
  import Plug.Conn, only: [assign: 3]
  import Pjeski.Users.UserSessionUtils, only: [get_current_subscription_id_from_conn: 1]

  alias PowInvitation.{Phoenix.Mailer, Plug}
  alias Pjeski.{Repo, Users, Users.User}

  import PjeskiWeb.ControllerHelpers.SubscriptionHelpers, only: [verify_if_subscription_is_expired: 2]

  plug :verify_if_subscription_is_expired when action in [:new, :create]
  plug :load_user_from_invitation_token when action in [:show, :edit, :update]
  plug :assign_create_path when action in [:new, :create]
  plug :assign_update_path when action in [:edit, :update]

  def new(conn, _params) do
    conn
    |> assign(:changeset, Plug.change_user(conn))
    |> render("new.html")
  end

  def create(conn, %{"user" => user_params}) do
    case Plug.create_user(conn, user_params) do
      {:ok, %{email: email} = user, conn} when is_binary(email) -> maybe_send_email_and_respond_success(conn, user)
      {:error, %{errors: [email: {_msg, [constraint: :unique, constraint_name: "users_email_index"]}]} = changeset, conn} ->
        user = Repo.get_by!(User, [email: changeset.changes.email])

        # TODO: when trying to add already attached user
        Users.upsert_subscription_link!(user.id, get_current_subscription_id_from_conn(conn), :raise)

        maybe_send_email_and_respond_success(conn, user)
      {:error, changeset, conn} ->
        conn
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def edit(conn, _params) do
    changeset = Plug.change_user(conn)

    conn
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def update(conn, %{"user" => user_params}) do
    case Plug.update_user(conn, user_params) do
      {:ok, _user, conn} ->
        conn
        |> put_flash(:info, gettext("User has been created"))
        |> redirect(to: Routes.live_path(PjeskiWeb.Endpoint, PjeskiWeb.DashboardLive.Index))
      {:error, changeset, conn} ->
        conn
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end

  defp load_user_from_invitation_token(%{params: %{"id" => token}} = conn, _opts) do
    case Plug.load_invited_user_by_token(conn, token) do
      {:error, conn}  ->
        conn
        |> put_flash(:error, gettext("Invalid token"))
        |> redirect(to: Routes.session_path(conn, :new))

      {:ok, conn} ->
        assign(conn, :invited_user, conn.assigns.invited_user |> Repo.preload(:last_used_subscription))
    end
  end



  defp deliver_email(conn, user) do
    url        = invitation_url(conn, user)
    invited_by = Pow.Plug.current_user(conn)
    email      = Mailer.invitation(conn, user, invited_by, url)

    Pow.Phoenix.Mailer.deliver(conn, email)
  end

  defp invitation_url(conn, user) do
    token = PowInvitation.Plug.sign_invitation_token(conn, user)

    Routes.invitation_path(conn, :edit, token)
  end

  defp assign_create_path(conn, _opts) do
    path = Routes.invitation_path(conn, :create)

    assign(conn, :action, path)
  end

  defp assign_update_path(%{params: %{"id" => token}} = conn, _opts) do
    path = Routes.invitation_path(conn, :update, token)
    assign(conn, :action, path)
  end

  def maybe_send_email_and_respond_success(conn, %{email_confirmed_at: nil} = user) do
    deliver_email(conn, user)

    conn
    |> put_flash(:info, gettext("Invitation e-mail sent"))
    |> redirect(to: Routes.user_path(conn, :index))
  end

  def maybe_send_email_and_respond_success(conn, _user) do
    conn
    |> put_flash(:info, gettext("Added user to your subscription"))
    |> redirect(to: Routes.user_path(conn, :index))
  end

end
