defmodule PjeskiWeb.Admin.UserView do
  use PjeskiWeb, :view

  import PjeskiWeb.RegistrationView, only: [ languages_select_options: 0 ]
  import PjeskiWeb.Admin.SubscriptionView, only: [
    all_subscriptions_options_with_empty: 0,
    determine_if_sorted: 4
  ]

  def toggle_admin_button(conn, user) do
    text = if user.role == "admin" do
      gettext("Revoke admin privileges")
    else
      gettext("Grant admin privileges")
    end

    link text, to: Routes.admin_user_user_path(conn, :toggle_admin, user), method: :put, data: [confirm: gettext("Are you sure?")], class: "button is-danger"
  end

  def user_roles_select_options do
    [
      [gettext("Admin"), "admin"],
      [gettext("User"), "user"],
    ] |> Map.new(fn [k, v] -> {k, v} end)
  end

  def subscription_name_link_for(_, %Pjeski.Users.User{subscription: nil}), do: gettext("empty")
  def subscription_name_link_for(conn, %Pjeski.Users.User{subscription: subscription}) do
    link subscription.name, to: Routes.admin_subscription_path(conn, :show, subscription.id)
  end

  def subscription_time_zone_for(%Pjeski.Users.User{subscription: nil}), do: gettext("empty")
  def subscription_time_zone_for(%Pjeski.Users.User{subscription: subscription}), do: subscription.time_zone

  def subscription_expires_datetime_for(%Pjeski.Users.User{subscription: nil}), do: gettext("empty")
  def subscription_expires_datetime_for(%Pjeski.Users.User{subscription: subscription}), do: subscription.expires_on
end
