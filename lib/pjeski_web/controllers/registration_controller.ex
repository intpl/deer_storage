defmodule PjeskiWeb.RegistrationController do
  use PjeskiWeb, :controller

  def new(conn, _params) do
    render(conn, "new.html", changeset: Pow.Plug.change_user(conn))
  end

  def edit(conn, _params) do
    render(conn, "edit.html", changeset: Pow.Plug.change_user(conn))
  end

  def create(conn, %{"user" => user_params}) do
    conn
    |> Pow.Plug.create_user(user_params)
    |> case do
      {:ok, _user, conn} ->
        conn
        |> put_flash(:info, "Welcome!")
        |> redirect(to: Routes.page_path(conn, :index))

      {:error, changeset, conn} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def update(conn, %{"user" => user_params}) do
    conn
    |> Pow.Plug.update_user(user_params)
    |> case do
      {:ok, _user, conn} ->
        conn
        |> put_flash(:info, "Changed succesfully!")
        |> redirect(to: Routes.page_path(conn, :index))

      {:error, changeset, conn} ->
        render(conn, "edit.html", changeset: changeset)
    end
  end
end
