defmodule PjeskiWeb.InvitationController do
  use PjeskiWeb, :controller
  import Plug.Conn, only: [assign: 3]

  alias PowInvitation.{Phoenix.Mailer, Plug}

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
        |> redirect(to: Routes.invitation_path(conn, :new))
      {:ok, user, conn} ->
        redirect(conn, to: Routes.invitation_path(conn, :show, user.invitation_token))
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
        IO.inspect changeset

        conn
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end

  defp load_user_from_invitation_token(%{params: %{"id" => token}} = conn, _opts) do
    case Plug.invited_user_from_token(conn, token) do
      nil  ->
        conn
        |> put_flash(:error, gettext("Invalid token"))
        |> redirect(to: Routes.session_path(conn, :new))

      user ->
        Plug.assign_invited_user(conn, user |> Pjeski.Repo.preload(:subscription))
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
