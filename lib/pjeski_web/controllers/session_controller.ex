defmodule PjeskiWeb.SessionController do
  use PjeskiWeb, :controller
  alias Pjeski.Users.UserSessionUtils
  alias Pjeski.Repo

  import PjeskiWeb.ConfirmationHelpers, only: [send_confirmation_email: 2]

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
              |> Pow.Plug.assign_current_user(user |> Repo.preload(:available_subscriptions), Pow.Plug.fetch_config(conn))
              |> UserSessionUtils.maybe_put_subscription_into_session
              |> put_session(:current_user_id, user.id)
              |> put_session(:locale, user.locale)
              |> redirect(to: dashboard_path_for(user))

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
    token = UserSessionUtils.get_token_from_conn(conn)
    Phoenix.PubSub.broadcast!(Pjeski.PubSub, "session_#{token}", :logout)

    conn
    |> Pow.Plug.delete
    |> redirect(to: Routes.page_path(conn, :index))
  end

  defp email_confirmed?(%{role: "admin"}), do: true
  defp email_confirmed?(%{email_confirmed_at: nil, email_confirmation_token: token, unconfirmed_email: nil}) when not is_nil(token), do: false
  defp email_confirmed?(_user), do: true
end
