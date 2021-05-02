defmodule DeerStorageWeb.ConfirmationController do
  use DeerStorageWeb, :controller

  def show(conn, %{"id" => token}) do
    case PowEmailConfirmation.Plug.confirm_email(conn, token) do
      {:ok, _user, conn} ->
        conn
        |> put_flash(:info, gettext("E-mail has been confirmed"))
        |> redirect(to: redirect_to(conn))
      {:error, _changeset, conn} ->
        conn
        |> put_flash(:error, gettext("Failed to confirm e-mail"))
        |> redirect(to: redirect_to(conn))
    end
  end


  defp redirect_to(conn) do
    case Pow.Plug.current_user(conn) do
      nil   -> Routes.session_path(conn, :new)
      _user -> Routes.registration_path(conn, :edit)
    end
  end
end
