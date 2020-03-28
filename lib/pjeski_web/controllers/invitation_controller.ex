defmodule PjeskiWeb.InvitationController do
  use PjeskiWeb, :controller
  import Plug.Conn, only: [assign: 3]

  alias PowInvitation.{Phoenix.Mailer, Plug}
  alias Pjeski.{Repo, Users, Users.User}

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
      {:ok, %{email: email} = user, conn} when is_binary(email) ->
        deliver_email(conn, user)

        conn
        |> put_flash(:info, gettext("Invitation e-mail sent"))
        |> redirect(to: Routes.user_path(conn, :index))
      {:error, changeset, conn} ->
        case changeset.errors[:email] do
          {_text, [constraint: :unique, constraint_name: "users_email_index"]} ->
            user = Repo.get_by!(User, [email: changeset.changes.email])

            Users.insert_subscription_link_and_maybe_change_id(user, Pow.Plug.current_user(conn).subscription_id)

            conn
            |> put_flash(:info, gettext("Added user to your subscription"))
            |> redirect(to: Routes.user_path(conn, :index))
          _ ->
            conn
            |> assign(:changeset, changeset)
            |> render("new.html")
        end
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

  defp verify_if_subscription_is_expired(%{assigns: %{current_user: current_user}} = conn, _opts) do
    user = current_user |> Repo.preload(:subscription) # let it fail if subscription_id is nil
    case Date.compare(Date.utc_today, user.subscription.expires_on) == :lt do
      true -> conn
      false ->
        conn
        |> put_flash(:error, gettext("Your subscription expired"))
        |> redirect(to: Routes.registration_path(conn, :edit))
    end
  end

  defp load_user_from_invitation_token(%{params: %{"id" => token}} = conn, _opts) do
    case Plug.invited_user_from_token(conn, token) do
      nil  ->
        conn
        |> put_flash(:error, gettext("Invalid token"))
        |> redirect(to: Routes.session_path(conn, :new))

      user ->
        Plug.assign_invited_user(conn, user |> Repo.preload(:subscription))
    end
  end

  defp deliver_email(conn, user) do
    url        = invitation_url(conn, user)
    invited_by = Pow.Plug.current_user(conn)
    email      = Mailer.invitation(conn, user, invited_by, url)

    Pow.Phoenix.Mailer.deliver(conn, email)
  end

  defp invitation_url(conn, user) do
    Routes.invitation_path(conn, :edit, user.invitation_token)
  end

  defp assign_create_path(conn, _opts) do
    path = Routes.invitation_path(conn, :create)

    assign(conn, :action, path)
  end

  defp assign_update_path(%{params: %{"id" => token}} = conn, _opts) do
    path = Routes.invitation_path(conn, :update, token)
    assign(conn, :action, path)
  end
end
