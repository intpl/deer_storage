defmodule PjeskiWeb.Admin.SubscriptionView do
  alias PjeskiWeb.Router.Helpers, as: Routes
  use PjeskiWeb, :view

  def determine_if_sorted(title, field, sort_by, query) do
    case Regex.scan(~r/(.*)_(.*)$/, sort_by) do
      [[_match, ^field, order]] ->
        case order do
            "asc" -> link("⮝ " <> title, to: "?sort_by=#{field}_desc&query=#{query}")
            "desc" -> link("⮟ " <> title, to: "?sort_by=#{field}_asc&query=#{query}")
        end
      _ -> link(title, to: "?sort_by=#{field}_desc&query=#{query}")
    end
  end

  def all_subscriptions_options_with_empty, do: [key: nil, value: nil] ++ all_subscriptions_options()
  def all_users_options_with_empty, do: [key: nil, value: nil] ++ all_users_options()

  def all_subscriptions_options do
    Pjeski.Subscriptions.list_subscriptions()
      |> Enum.map(fn subscription -> [key: "#{subscription.name}", value: subscription.id]  end)
  end

  def all_users_options do
    Pjeski.Users.list_users()
      |> Enum.map(fn user -> [key: "#{user.name}", value: user.id]  end)
  end

  def subscriptions_sorting_options do
    descending = " (#{gettext("descending")})"
    ascending = " (#{gettext("ascending")})"

    [
      ["", gettext("No sorting")],
      ["name_desc", gettext("Name") <> descending],
      ["name_asc", gettext("Name") <> ascending],
      ["expires_on_desc", gettext("Expires on") <> descending],
      ["expires_on_asc", gettext("Expires on") <> ascending],
      ["admin_notes_desc", gettext("Admin notes") <> descending],
      ["admin_notes_asc", gettext("Admin notes") <> ascending],
      ["inserted_at_desc", gettext("Inserted at") <> descending],
      ["inserted_at_asc", gettext("Inserted at") <> ascending],
      ["updated_at_desc", gettext("Updated at") <> descending],
      ["updated_at_asc", gettext("Updated at") <> ascending],
      ["users_count_desc", gettext("Users") <> descending],
      ["users_count_asc", gettext("Users") <> ascending]
    ]
  end
end
