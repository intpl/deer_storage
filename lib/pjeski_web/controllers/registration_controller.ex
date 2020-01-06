defmodule PjeskiWeb.RegistrationController do
  use PjeskiWeb, :controller

  alias Pjeski.Users.User

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
      {:ok, _user, conn} ->
        conn |> redirect(to: dashboard_path_for(:user))

      {:error, changeset, conn} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def update(conn, %{"user" => user_params}) do
    conn
    |> Pow.Plug.update_user(user_params)
    |> case do
      {:ok, %User{role: role}, conn} ->
        conn |> redirect(to: dashboard_path_for(role))

      {:error, changeset, conn} ->
        render(conn, "edit.html", changeset: changeset, navigation_template_always: "navigation_outside_app.html")
    end
  end
end
