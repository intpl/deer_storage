defmodule DeerStorageWeb.SessionController do
  require Logger
  use DeerStorageWeb, :controller

  import DeerStorage.FeatureFlags, only: [mailing_enabled?: 0]
  import DeerStorageWeb.ControllerHelpers.ConfirmationHelpers, only: [send_confirmation_email: 2]
  import DeerStorageWeb.ControllerHelpers.UserHelpers, only: [redirect_to_dashboard: 2]

  import DeerStorage.Users.UserSessionUtils,
    only: [
      assign_current_user_and_preload_available_subscriptions: 2,
      get_token_from_conn: 1,
      maybe_put_subscription_into_session: 1,
      put_into_session: 3
    ]

  def new(conn, _params) do
    changeset = Pow.Plug.change_user(conn)

    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case conn |> Pow.Plug.authenticate_user(user_params) do
      {:ok, conn} ->
        user = conn |> Pow.Plug.current_user()

        case email_confirmed?(user) do
          true ->
            Logger.info("User (id #{user.id}) signing in...")

            conn
            |> assign_current_user_and_preload_available_subscriptions(user)
            |> maybe_put_subscription_into_session
            |> put_into_session(:locale, user.locale)
            |> put_into_session(:current_user_id, user.id)
            # this will be assigned to session on next request
            |> redirect_to_dashboard(user.last_used_subscription_id)

          false ->
            maybe_resend_confirmation_email(conn, user)
        end

      {:error, conn} ->
        changeset = Pow.Plug.change_user(conn, conn.params["user"])

        conn
        |> put_flash(:error, gettext("Invalid e-mail or password"))
        |> render("new.html", changeset: changeset)
    end
  end

  def delete(conn, _params) do
    token = get_token_from_conn(conn)
    Phoenix.PubSub.broadcast!(DeerStorage.PubSub, "session_#{token}", :logout)

    conn
    |> Pow.Plug.delete()
    |> clear_session
    |> redirect(to: Routes.page_path(conn, :index))
  end

  defp maybe_resend_confirmation_email(conn, user) do
    case mailing_enabled?() do
      true -> send_confirmation_email_and_delete_session(conn, user)
      false -> notice_about_unconfirmed_email_by_administrator(conn)
    end
  end

  defp notice_about_unconfirmed_email_by_administrator(conn) do
    delete_session_and_put_flash(
      conn,
      gettext("You have to be confirmed by an administrator before you can log in")
    )
  end

  defp send_confirmation_email_and_delete_session(conn, user) do
    send_confirmation_email(user, conn)

    delete_session_and_put_flash(
      conn,
      gettext("E-mail not confirmed. Confirmation e-mail has been sent again")
    )
  end

  defp delete_session_and_put_flash(conn, translated_flash) do
    conn
    |> Pow.Plug.delete()
    |> put_flash(:info, translated_flash)
    |> redirect(to: Routes.session_path(conn, :new))
  end

  defp email_confirmed?(%{role: "admin"}), do: true

  defp email_confirmed?(%{
         email_confirmed_at: nil,
         email_confirmation_token: token,
         unconfirmed_email: nil
       })
       when not is_nil(token), do: false

  defp email_confirmed?(_user), do: true
end
