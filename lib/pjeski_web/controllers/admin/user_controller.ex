defmodule PjeskiWeb.Admin.UserController do
  use PjeskiWeb, :controller

  alias Pjeski.Users
  alias Pjeski.Users.User

  def index(conn, _params) do
    users = Users.list_users()
    render(conn, "index.html", users: users)
  end

  def new(conn, _params) do
    changeset = Users.change_user(%User{})
    render(conn, "new.html", changeset: changeset, action: Routes.admin_user_path(conn, :create))
  end

  def create(conn, %{"user" => user_params}) do
    case Users.admin_create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: Routes.admin_user_path(conn, :show, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset, action: Routes.admin_user_path(conn, :create))
    end
  end

  def show(conn, %{"id" => id}) do
    user = Users.get_user!(id)

    render(conn, "show.html", user: user, user_log_in_sessions_count: length(user_log_in_sessions(user)))
  end

  def edit(conn, %{"id" => id}) do
    user = Users.get_user!(id)
    changeset = Users.change_user(user)
    render(conn, "edit.html", user: user, changeset: changeset, action: Routes.admin_user_path(conn, :update, id))
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Users.get_user!(id)

    case Users.admin_update_user(user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: Routes.admin_user_path(conn, :show, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", user: user, changeset: changeset, action: Routes.admin_user_path(conn, :update, id))
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Users.get_user!(id)
    {:ok, _user} = Users.delete_user(user)

    conn
    |> put_flash(:info, "User deleted successfully.")
    |> redirect(to: Routes.admin_user_path(conn, :index))
  end

  def toggle_admin(conn, %{"user_id" => id}) do
    user = Users.get_user!(id)
    {:ok, user} = Users.toggle_admin(user)

    conn
    |> put_flash(:info, gettext("%{name} is now '%{role}'", name: user.name, role: user.role))
    |> redirect(to: Routes.admin_user_path(conn, :show, user))
  end

  def log_out_from_devices(conn, %{"user_id" => id}) do
    user = Users.get_user!(id)
    {:ok} = delete_all_sessions_for_user(user)

    conn
    |> put_flash(:info, gettext("%{name} has been logged out from all devices", name: user.name))
    |> redirect(to: Routes.admin_user_path(conn, :show, user))
  end

  defp user_log_in_sessions(user) do
    Pow.Store.CredentialsCache.sessions(pow_backend_config_reuse(), user)
  end

  defp delete_all_sessions_for_user(user) do
    for session_key <- user_log_in_sessions(user) do
      Pow.Store.CredentialsCache.delete(pow_backend_config_reuse(), session_key)
    end

    {:ok}
  end

  defp pow_backend_config_reuse, do: [backend: Application.get_env(:pjeski, :pow)[:cache_store_backend]]
end
