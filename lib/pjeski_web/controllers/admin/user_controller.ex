defmodule PjeskiWeb.Admin.UserController do
  use PjeskiWeb, :controller

  alias Pjeski.Users
  alias Pjeski.Users.User
  alias Pjeski.Users.UserSessionUtils

  def search(conn, params) do
    query = params["query"] || ""

    users = Users.list_users(query, 1, 100, "")
    |> Enum.map(fn user -> %{id: user.id, text: user.name <> " (#{user.email})"} end)

    json(conn, users)
  end

  def index(conn, params) do
    query = params["query"] || ""
    sort_by = params["sort_by"] || ""

    per_page = 50
    page = String.to_integer(params["page"] || "1")
    users = Users.list_users(query, page, per_page, sort_by)

    rendered_pagination = Phoenix.View.render_to_string(
      PjeskiWeb.Admin.UserView, "_index_pagination.html",
      %{conn: conn, count: length(users), per_page: per_page, page: page, query: query, sort_by: sort_by}
    )

    render(
      conn,
      "index.html",
      users: users,
      page: page,
      rendered_pagination: rendered_pagination,
      query: query,
      sort_by: sort_by
    )
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
    user = Users.get_user!(id) |> Pjeski.Repo.preload(:available_subscriptions)
    available_subscriptions = user.available_subscriptions
    count = length(UserSessionUtils.user_sessions_keys(user))
    excluded_subscriptions_ids = available_subscriptions
    |> Enum.map(fn s -> s.id end)
    |> Poison.encode!

    render(
      conn,
      "show.html",
      user: user,
      available_subscriptions: available_subscriptions,
      user_log_in_sessions_count: count,
      excluded_subscriptions_ids: excluded_subscriptions_ids
    )
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
    UserSessionUtils.delete_all_sessions_for_user!(user)
    Phoenix.PubSub.broadcast!(Pjeski.PubSub, "user_#{user.id}", :logout)

    conn
    |> put_flash(:info, gettext("%{name} has been logged out from all devices", name: user.name))
    |> redirect(to: Routes.admin_user_path(conn, :show, user))
  end
end
