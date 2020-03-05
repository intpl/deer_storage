defmodule PjeskiWeb.Admin.SubscriptionView do
  alias PjeskiWeb.Router.Helpers, as: Routes
  use PjeskiWeb, :view

  import PjeskiWeb.RegistrationView, only: [
    time_zones_select_options: 0
  ]

  def determine_if_sorted(title, field, sort_by, query) do
    case Regex.scan(~r/(.*)_(.*)$/, sort_by) do
      [[_match, ^field, order]] ->
        case order do
            "asc" -> link("⮟ " <> title, to: "?sort_by=#{field}_desc&query=#{query}")
            "desc" -> link("⮝ " <> title, to: "?sort_by=#{field}_asc&query=#{query}")
        end
      _ -> link(title, to: "?sort_by=#{field}_asc&query=#{query}")
    end
  end

  def all_subscriptions_options_with_empty, do: Map.merge %{nil => nil}, all_subscriptions_options()

  def all_subscriptions_options do
    Pjeski.Subscriptions.list_subscriptions()
      |> Enum.map(fn subscription -> ["#{subscription.name} (#{subscription.email})", subscription.id]  end)
      |> Map.new(fn [k, v] -> {k, v} end)
  end
end
