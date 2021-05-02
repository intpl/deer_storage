defmodule DeerStorageWeb.ResetPasswordController do
  import DeerStorage.FeatureFlags, only: [mailing_enabled?: 0]
  import DeerStorageWeb.ControllerHelpers.FeatureFlagsHelpers

  use DeerStorageWeb, :controller

  alias Plug.Conn
  alias Pow.Plug, as: PowPlug
  alias PowResetPassword.{Phoenix.Mailer, Plug}

  plug :load_user_from_reset_token when action in [:edit, :update]
  plug :assign_create_path when action in [:new, :create]
  plug :assign_update_path when action in [:edit, :update]

  def new(conn, _params) do
    wrap_feature_endpoint(mailing_enabled?(), conn, fn ->
      conn
      |> assign(:changeset, Plug.change_user(conn))
      |> render("new.html")
    end)
  end

  def create(conn, %{"user" => user_params}) do
    wrap_feature_endpoint(mailing_enabled?(), conn, fn ->
      case Plug.create_reset_token(conn, user_params) do
        {:ok, %{token: token, user: user}, conn} ->
          url = Routes.reset_password_path(conn, :edit, token)
          deliver_email(conn, user, url)

          conn
          |> put_flash(:info, gettext("Email has been sent"))
          |> redirect(to: Routes.session_path(conn, :new))
        {:error, changeset, conn} ->
          case PowPlug.__prevent_user_enumeration__(conn, nil) do
            true ->
              conn
              |> put_flash(:info, gettext("Email has been sent"))
              |> redirect(to: Routes.session_path(conn, :new))

            false ->
              conn
              |> assign(:changeset, changeset)
              |> put_flash(:error, gettext("User not found"))
              |> render("new.html")
          end
      end
    end)
  end

  def edit(conn, _params) do
    wrap_feature_endpoint(mailing_enabled?(), conn, fn ->
      changeset = Plug.change_user(conn)

      conn
      |> assign(:changeset, changeset)
      |> render("edit.html")
    end)
  end

  def update(conn, %{"user" => user_params}) do
    wrap_feature_endpoint(mailing_enabled?(), conn, fn ->
      case Plug.update_user_password(conn, user_params) do
        {:ok, _user, conn} ->
          conn
          |> put_flash(:info, gettext("Password has been changed"))
          |> redirect(to: Routes.session_path(conn, :new))
        {:error, changeset, conn} ->
          conn
          |> assign(:changeset, changeset)
          |> render("edit.html")
      end
    end)
  end

  defp load_user_from_reset_token(%{params: %{"id" => token}} = conn, _opts) do
    case Plug.load_user_by_token(conn, token) do
      {:error, conn} ->
        conn
        |> put_flash(:error, gettext("Invalid token"))
        |> redirect(to: Routes.reset_password_path(conn, :new))
        |> halt()

      {:ok, conn} ->
        conn
    end
  end

  defp deliver_email(conn, user, url) do
    email = Mailer.reset_password(conn, user, url)

    Pow.Phoenix.Mailer.deliver(conn, email)
  end

  defp assign_create_path(conn, _opts) do
    path = Routes.reset_password_path(conn, :create)
    Conn.assign(conn, :action, path)
  end

  defp assign_update_path(conn, _opts) do
    token = conn.params["id"]
    path  = Routes.reset_password_path(conn, :update, token)
    Conn.assign(conn, :action, path)
  end
end
