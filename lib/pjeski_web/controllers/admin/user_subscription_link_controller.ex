defmodule PjeskiWeb.Admin.UserSubscriptionLinkController do
  use PjeskiWeb, :controller

  alias Pjeski.Users

  def reset(conn, %{"user_id" => user_id}) do
    user = Users.get_user!(user_id)

    Users.update_last_used_subscription_id!(user, nil)

    conn
    |> put_flash(:info, gettext("User current database has been reset"))
    |> redirect(to: Routes.admin_user_path(conn, :show, user))
  end

  def make_current(conn, %{"user_id" => user_id, "subscription_id" => subscription_id}) do
    user = Users.get_user!(user_id)
    subscription_id = subscription_id |> String.to_integer

    Users.update_last_used_subscription_id!(user, subscription_id)

    conn
    |> put_flash(:info, gettext("User current database has been changed"))
    |> redirect(to: Routes.admin_user_path(conn, :show, user))
  end

  def delete(conn, %{"id" => user_id, "subscription_id" => subscription_id} = params), do: delete_user_subscription_link(conn, params, user_id, subscription_id)
  def delete(conn, %{"user_id" => user_id, "id" => subscription_id} = params), do: delete_user_subscription_link(conn, params, user_id, subscription_id)

  def create(conn, %{"user_id" => user_id, "subscription_id" => subscription_id} = params) do
    user = Users.get_user!(user_id)
    subscription_id = subscription_id |> String.to_integer

    # TODO: validate presence of user_id and subscription_id

    Users.insert_subscription_link_and_maybe_change_last_used_subscription_id(user, subscription_id)

    conn
    |> put_flash(:info, gettext("User has been connected to this database"))
    |> redirect(to: path_to_redirect(conn, params))
  end

  defp delete_user_subscription_link(conn, params, user_id, subscription_id) do
    user = Users.get_user!(user_id)
    subscription_id = subscription_id |> String.to_integer

    Users.remove_subscription_link_and_maybe_change_last_used_subscription_id(user, subscription_id)

    conn
    |> put_flash(:info, gettext("User has been disconnected from this database"))
    |> redirect(to: path_to_redirect(conn, params))
  end

  defp path_to_redirect(conn, %{"subscription_id" => id, "redirect_back_to" => "subscription"}), do: Routes.admin_subscription_path(conn, :show, id)
  defp path_to_redirect(conn, %{"user_id" => id, "redirect_back_to" => "user"}), do: Routes.admin_user_path(conn, :show, id)
end
