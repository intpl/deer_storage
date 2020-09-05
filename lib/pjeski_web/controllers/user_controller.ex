defmodule PjeskiWeb.UserController do
  use PjeskiWeb, :controller
  alias Pjeski.Repo
  alias Pjeski.Users.User
  alias Pjeski.Users.UserSessionUtils

  import Plug.Conn, only: [assign: 3]

  import Pjeski.Users, only: [
    ensure_user_subscription_link!: 2,
    ensure_user_subscription_link!: 3,
    remove_subscription_link_and_maybe_change_last_used_subscription_id: 2,
    toggle_permission_for_user_subscription_link!: 2
  ]

  def toggle_permission(%{assigns: %{current_user: %{id: current_user_id, role: current_user_role}}} = conn, %{"subscription_id" => subscription_id, "user_id" => user_id, "permission_key" => permission_key}) do
    subscription_id = String.to_integer(subscription_id)
    user_id = String.to_integer(user_id)

    if current_user_id == user_id, do: raise "attempt to change own permissions"

    case current_user_role do
      "admin" -> nil
      "user" -> ensure_user_subscription_link!(current_user_id, subscription_id, [:permission_to_manage_users])
    end

    ensure_user_subscription_link!(user_id, subscription_id)
    |> toggle_permission_for_user_subscription_link!(String.to_existing_atom(permission_key))

    conn |> put_flash(:info, gettext("User's permissions changed")) |> redirect(to: Routes.user_path(conn, :index))
  end

  def unlink(%{assigns: %{current_user: %{id: current_user_id, role: current_user_role}}} = conn, %{"subscription_id" => subscription_id, "user_id" => user_id}) do
    subscription_id = String.to_integer(subscription_id)
    user_id = String.to_integer(user_id)

    case current_user_role do
      "admin" -> nil
      "user" -> ensure_user_subscription_link!(current_user_id, subscription_id, [:permission_to_manage_users])
    end

    user = Repo.get!(User, user_id)

    remove_subscription_link_and_maybe_change_last_used_subscription_id(user, subscription_id)
    maybe_logout_user!(user, subscription_id)

    conn
    |> put_flash(:info, gettext("User has been removed from your subscription"))
    |> redirect(to: Routes.user_path(conn, :index))
  end

  def index(%{assigns: %{current_user: %{id: current_user_id, role: current_user_role}, current_subscription: %{id: current_subscription_id}}} = conn, _params) do
    users_with_permissions = Pjeski.Users.list_users_for_subscription_id_with_permissions(current_subscription_id)
    {_, current_user_permissions} = Enum.find(users_with_permissions, fn {user, _} -> user.id == current_user_id  end)

    conn
    |> assign(:current_user_can_manage_users, current_user_permissions.permission_to_manage_users || current_user_role == "admin")
    |> assign(:users, users_with_permissions)
    |> render("index.html")
  end

  defp maybe_logout_user!(%{last_used_subscription_id: subscription_id} = user, subscription_id) do
    Phoenix.PubSub.broadcast!(Pjeski.PubSub, "user_#{user.id}", :logout)
    UserSessionUtils.delete_all_sessions_for_user!(user)
  end

  defp maybe_logout_user!(_, _), do: nil
end
