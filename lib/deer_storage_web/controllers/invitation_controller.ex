defmodule DeerStorageWeb.InvitationController do
  use DeerStorageWeb, :controller

  alias DeerStorage.FeatureFlags
  import Plug.Conn, only: [assign: 3]

  import DeerStorage.Users.UserSessionUtils,
    only: [
      assign_current_user_and_preload_available_subscriptions: 2,
      maybe_put_subscription_into_session: 1
    ]

  alias PowInvitation.{Phoenix.Mailer, Plug}
  alias DeerStorage.{Repo, Users, Users.User}

  import DeerStorageWeb.ControllerHelpers.SubscriptionHelpers,
    only: [verify_if_subscription_is_expired: 2]

  plug :verify_if_subscription_is_expired when action in [:new, :create]
  plug :load_user_from_invitation_token when action in [:show, :edit, :update]
  plug :assign_create_path when action in [:new, :create]
  plug :assign_update_path when action in [:edit, :update]
  plug :ensure_user_can_manage_users! when action in [:new, :create]

  def new(conn, _params) do
    conn
    |> assign(:changeset, Plug.change_user(conn))
    |> render("new.html")
  end

  def create(%{assigns: %{current_subscription: %{id: current_subscription_id}}} = conn, %{
        "user" => user_params
      }) do
    case [FeatureFlags.mailing_enabled?(), Plug.create_user(conn, user_params)] do
      [true, {:ok, %{email: email} = user, conn}] when is_binary(email) ->
        Users.insert_subscription_link_and_maybe_change_last_used_subscription_id(
          user,
          current_subscription_id
        )

        maybe_send_email_and_respond_success(conn, user)

      [false, {:ok, %{email: email} = _user, conn}] when is_binary(email) ->
        conn
        |> put_flash(
          :error,
          gettext(
            "Emails are disabled. New users must be confirmed by an administrator before you can invite them."
          )
        )
        |> redirect(to: Routes.user_path(conn, :index))

      [
        _mailing_enabled?,
        {:error,
         %{errors: [email: {_msg, [constraint: :unique, constraint_name: "users_email_index"]}]} =
             changeset, conn}
      ] ->
        user = Repo.get_by!(User, email: changeset.changes.email)

        Users.upsert_subscription_link!(user.id, current_subscription_id, :nothing)

        maybe_send_email_and_respond_success(conn, user)

      [_mailing_enabled?, {:error, changeset, conn}] ->
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
      {:ok, user, conn} ->
        conn
        |> assign_current_user_and_preload_available_subscriptions(user)
        |> put_flash(:info, gettext("User has been created"))
        |> maybe_put_subscription_into_session
        |> redirect(
          to: Routes.live_path(DeerStorageWeb.Endpoint, DeerStorageWeb.DeerDashboardLive.Index)
        )

      {:error, changeset, conn} ->
        conn
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end

  defp load_user_from_invitation_token(%{params: %{"id" => token}} = conn, _opts) do
    case Plug.load_invited_user_by_token(conn, token) do
      {:error, conn} ->
        conn
        |> put_flash(:error, gettext("Invalid token"))
        |> redirect(to: Routes.session_path(conn, :new))

      {:ok, conn} ->
        assign(
          conn,
          :invited_user,
          conn.assigns.invited_user |> Repo.preload(:last_used_subscription)
        )
    end
  end

  defp ensure_user_can_manage_users!(
         %{assigns: %{current_subscription: %{id: current_subscription_id}}} = conn,
         _
       ) do
    current_user = Pow.Plug.current_user(conn)

    case current_user.role do
      "admin" ->
        conn

      "user" ->
        Users.ensure_user_subscription_link!(
          current_user.id,
          current_subscription_id,
          [:permission_to_manage_users]
        )

        conn
    end
  end

  defp deliver_email(conn, user) do
    url = invitation_url(conn, user)
    invited_by = Pow.Plug.current_user(conn)
    email = Mailer.invitation(conn, user, invited_by, url)

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
    |> put_flash(:info, gettext("Added user to your database"))
    |> redirect(to: Routes.user_path(conn, :index))
  end
end
