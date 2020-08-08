defmodule PjeskiWeb.LayoutView do
  use PjeskiWeb, :view

  def title(conn) do
    case conn.assigns[:title] do
      nil -> gettext("StorageDeer")
      title -> title
    end
  end

  def compact_tables_to_ids_and_names(deer_tables) do
    Enum.map(deer_tables, fn %{id: id, name: name} = result -> result end)
  end

  def header_text(%{assigns: %{current_subscription_is_expired: true}}), do: gettext("SUBSCRIPTION EXPIRED")
  def header_text(%{assigns: %{current_subscription: %{name: name}}}), do: name
  def header_text(%{assigns: %{current_user: %{name: name}}}), do: name
  def header_text(_), do: gettext("StorageDeer")

  def render_navigation(%{assigns: %{current_user: nil}} = conn), do: render "navigation_guest.html", conn: conn
  def render_navigation(%{assigns: %{current_user: %{role: "admin"}, current_subscription: nil}} = conn) do
    render "navigation_admin.html", conn: conn
  end
  def render_navigation(conn), do: render "navigation_user.html", conn: conn
end
