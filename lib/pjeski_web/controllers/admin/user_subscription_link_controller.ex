defmodule PjeskiWeb.Admin.UserSubscriptionLinkController do
  use PjeskiWeb, :controller

  alias Pjeski.Users

  def reset(conn, %{"user_id" => user_id}) do
    user = Users.get_user!(user_id)

    Users.update_subscription_id!(user, nil)

    conn
    |> put_flash(:info, gettext("User current subscription has been reset"))
    |> redirect(to: Routes.admin_user_path(conn, :show, user))
  end

  def make_current(conn, %{"user_id" => user_id, "subscription_id" => subscription_id}) do
    user = Users.get_user!(user_id)
    subscription_id = subscription_id |> String.to_integer

    Users.update_subscription_id!(user, subscription_id)

    conn
    |> put_flash(:info, gettext("User current subscription has been changed"))
    |> redirect(to: Routes.admin_user_path(conn, :show, user))
  end

  def delete(conn, %{"user_id" => user_id, "id" => subscription_id}) do
    user = Users.get_user!(user_id)
    subscription_id = subscription_id |> String.to_integer

    # TODO: validate presence of user_id and subscription_id

    Users.remove_subscription_link_and_maybe_change_id(user, subscription_id)

    conn
    |> put_flash(:info, gettext("User has been disconnected from this Subscription"))
    |> redirect(to: Routes.admin_user_path(conn, :show, user))
  end

  def create(conn, %{"user_id" => user_id, "subscription_id" => subscription_id}) do
    user = Users.get_user!(user_id)
    subscription_id = subscription_id |> String.to_integer

    # TODO: validate presence of user_id and subscription_id

    Users.insert_subscription_link_and_maybe_change_id(user, subscription_id)

    conn
    |> put_flash(:info, gettext("User has been connected to this Subscription"))
    |> redirect(to: Routes.admin_user_path(conn, :show, user))
  end
end
