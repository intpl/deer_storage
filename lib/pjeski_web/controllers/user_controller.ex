defmodule PjeskiWeb.UserController do
  use PjeskiWeb, :controller
  alias Pjeski.Repo
  alias Pjeski.Users.User
  alias Pjeski.Users.UserSessionUtils

  import Plug.Conn, only: [assign: 3]

  import Pjeski.Users, only: [ensure_user_subscription_link!: 2, remove_subscription_link_and_maybe_change_last_used_subscription_id: 2]

  def unlink(%{assigns: %{current_user: %{id: current_user_id}}} = conn, %{"subscription_id" => subscription_id, "user_id" => user_id}) do
    subscription_id = String.to_integer(subscription_id)
    user_id = String.to_integer(user_id)
    ensure_user_subscription_link!(current_user_id, subscription_id)

    user = Repo.get!(User, user_id)

    raise_if_equal(user_id, current_user_id)
    remove_subscription_link_and_maybe_change_last_used_subscription_id(user, subscription_id)
    maybe_logout_user!(user, subscription_id)

    conn
    |> put_flash(:info, gettext("User has been removed from your subscription"))
    |> redirect(to: Routes.user_path(conn, :index))
  end

  def index(%{assigns: %{current_subscription: %{id: current_subscription_id}}} = conn, _params) do
    conn
    |> assign(:users, Pjeski.Users.list_users_for_subscription_id(current_subscription_id))
    |> render("index.html")
  end

  defp maybe_logout_user!(%{last_used_subscription_id: subscription_id} = user, subscription_id) do
    Phoenix.PubSub.broadcast!(Pjeski.PubSub, "user_#{user.id}", :logout)
    UserSessionUtils.delete_all_sessions_for_user!(user)
  end

  defp maybe_logout_user!(_, _), do: nil

  defp raise_if_equal(id, id), do: raise("attempt to remove themselves")
  defp raise_if_equal(_, _), do: nil
end
