defmodule PjeskiWeb.SessionController do
  use PjeskiWeb, :controller

  import PjeskiWeb.ControllerHelpers.ConfirmationHelpers, only: [send_confirmation_email: 2]

  import Pjeski.Users.UserSessionUtils, only: [
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
              conn
              |> assign_current_user_and_preload_available_subscriptions(user)
              |> maybe_put_subscription_into_session
              |> put_into_session(:current_user_id, user.id)
              |> put_into_session(:locale, user.locale)
              |> redirect_to_dashboard(user.last_used_subscription_id) # this will be assigned to session on next request

            false ->
              send_confirmation_email(user, conn)

              conn
              |> Pow.Plug.delete
              |> put_flash(:info, gettext("E-mail not confirmed. Confirmation e-mail has been sent again"))
              |> redirect(to: Routes.session_path(conn, :new))
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
    Phoenix.PubSub.broadcast!(Pjeski.PubSub, "session_#{token}", :logout)

    conn
    |> Pow.Plug.delete
    |> clear_session
    |> redirect(to: Routes.page_path(conn, :index))
  end

  def redirect_to_dashboard(%{assigns: %{current_user: %{role: "admin"}}} = conn, nil) do
    conn |> redirect(to: Routes.admin_live_path(conn, PjeskiWeb.Admin.DashboardLive.Index))
  end
  def redirect_to_dashboard(conn, _), do: conn |> redirect(to: Routes.live_path(conn, PjeskiWeb.DashboardLive.Index))


  defp email_confirmed?(%{role: "admin"}), do: true
  defp email_confirmed?(%{email_confirmed_at: nil, email_confirmation_token: token, unconfirmed_email: nil}) when not is_nil(token), do: false
  defp email_confirmed?(_user), do: true
end
