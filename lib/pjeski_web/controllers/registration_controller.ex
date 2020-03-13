defmodule PjeskiWeb.RegistrationController do
  use PjeskiWeb, :controller

  alias Pjeski.Users
  alias Pjeski.Users.User

  import PjeskiWeb.ConfirmationHelpers, only: [send_confirmation_email: 2]

  def new(conn, _params) do
    render(conn, "new.html", changeset: Pow.Plug.change_user(conn))
  end

  def edit(conn, _params) do
    render(conn, "edit.html", changeset: Pow.Plug.change_user(conn), navigation_template_always: "navigation_outside_app.html")
  end

  def create(conn, %{"user" => user_params}) do
    conn
    |> Pow.Plug.create_user(user_params)
    |> case do
      {:ok, user, conn} ->
        Users.notify_subscribers({:ok, user}, [:user, :created])
        send_confirmation_email(user, conn)

        conn
        |> Pow.Plug.delete
        |> put_flash(:info, gettext("Please confirm your e-mail before logging in"))
        |> redirect(to: Routes.session_path(conn, :new))
      {:error, changeset, conn} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def update(conn, %{"user" => user_params}) do
    conn |> Pow.Plug.update_user(user_params) |> case do
      {:ok, %User{role: role}, conn} ->
        conn
        |> maybe_send_confirmation_email
        |> redirect(to: dashboard_path_for(role))

      {:error, changeset, conn} ->
        render(conn, "edit.html", changeset: changeset, navigation_template_always: "navigation_outside_app.html")
    end
  end

  def maybe_send_confirmation_email(%{assigns: %{current_user: %User{email: email, unconfirmed_email: email}}} = conn), do: conn
  def maybe_send_confirmation_email(%{assigns: %{current_user: %User{email: _, unconfirmed_email: nil}}} = conn), do: conn
  def maybe_send_confirmation_email(%{assigns: %{current_user: %User{email: _, unconfirmed_email: _} = user}} = conn) do
    send_confirmation_email(user, conn)

    conn
    |> put_flash(:info, gettext("Click the link in the confirmation email to change your email."))
  end
end
