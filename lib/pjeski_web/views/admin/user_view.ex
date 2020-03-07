defmodule PjeskiWeb.Admin.UserView do
  use PjeskiWeb, :view

  import PjeskiWeb.RegistrationView, only: [ languages_select_options: 0 ]
  import PjeskiWeb.Admin.SubscriptionView, only: [all_subscriptions_options_with_empty: 0]

  def determine_if_sorted(title, field, sort_by, search_by, query) do
    case Regex.scan(~r/(.*)_(.*)$/, sort_by) do
      [[_match, ^field, order]] ->
        case order do
            "asc" -> link("⮝ " <> title, to: "?sort_by=#{field}_desc&query=#{query}&search_by=#{search_by}")
            "desc" -> link("⮟ " <> title, to: "?sort_by=#{field}_asc&query=#{query}&search_by=#{search_by}")
        end
      _ -> link(title, to: "?sort_by=#{field}_desc&query=#{query}&search_by=#{search_by}")
    end
  end

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

  def users_sorting_options do
    descending = " (#{gettext("descending")})"
    ascending = " (#{gettext("ascending")})"

    [
      ["", gettext("No sorting")],
      ["name_desc", gettext("Name and surname") <> descending],
      ["name_asc", gettext("Name and surname") <> ascending],
      ["email_desc", gettext("E-mail") <> descending],
      ["email_asc", gettext("E-mail") <> ascending],
      ["locale_desc", gettext("Locale") <> descending],
      ["locale_asc", gettext("Locale") <> ascending],
      ["role_desc", gettext("Role") <> descending],
      ["role_asc", gettext("Role") <> ascending],
      ["admin_notes_desc", gettext("Admin notes") <> descending],
      ["admin_notes_asc", gettext("Admin notes") <> ascending],
      ["inserted_at_desc", gettext("Inserted at") <> descending],
      ["inserted_at_asc", gettext("Inserted at") <> ascending],
      ["updated_at_desc", gettext("Updated at") <> descending],
      ["updated_at_asc", gettext("Updated at") <> ascending],
      ["subscription_name_desc", gettext("Subscription") <> descending],
      ["subscription_name_asc", gettext("Subscription") <> ascending],
      ["subscription_expires_on_desc", gettext("Subscription ends") <> descending],
      ["subscription_expires_on_asc", gettext("Subscription ends") <> ascending]
    ]
  end
end
