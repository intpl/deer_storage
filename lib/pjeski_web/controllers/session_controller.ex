defmodule PjeskiWeb.SessionController do
  use PjeskiWeb, :controller

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
              current_user = Pjeski.Repo.preload(user, :subscription)

              conn
              |> Pow.Plug.assign_current_user(current_user, Pow.Plug.fetch_config(conn))
              |> put_session(:current_user_id, current_user.id)
              |> put_session(:locale, current_user.locale)
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

  def delete(%{private: %{plug_session: %{"pjeski_auth" => token}}} = conn, _params) do
    Phoenix.PubSub.broadcast!(Pjeski.PubSub, "session_#{token}", :logout)

    conn
    |> Pow.Plug.delete
    |> redirect(to: Routes.page_path(conn, :index))
  end

  defp email_confirmed?(%{role: "admin"}), do: true
  defp email_confirmed?(%{email_confirmed_at: nil, email_confirmation_token: token, unconfirmed_email: nil}) when not is_nil(token), do: false
  defp email_confirmed?(_user), do: true
end
