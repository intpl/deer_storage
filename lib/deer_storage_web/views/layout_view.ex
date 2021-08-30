defmodule DeerStorageWeb.LayoutView do
  import DeerStorage.FeatureFlags, only: [registration_enabled?: 0]
  use DeerStorageWeb, :view

  def available_languages_and_locales(), do: [{"Polski", "pl"}, {"English", "en"}]

  def maybe_active_dashboard_link(socket, header_str) do
    header_str = if header_str, do: "🏠 " <> header_str
    class = case socket.view do
              DeerStorageWeb.DeerDashboardLive.Index -> "navbar-item has-text-weight-bold is-active"
              _ -> "navbar-item has-text-weight-bold"
              end


    live_redirect(header_str, to: Routes.live_path(socket, DeerStorageWeb.DeerDashboardLive.Index), class: class)
  end

  def maybe_active_records_link(socket, %{id: id} = dt, id) do
    live_redirect "#{dt.name} (#{dt.count})", to: Routes.live_path(socket, DeerStorageWeb.DeerRecordsLive.Index, dt.id), class: "navbar-item is-active"
  end

  def maybe_active_records_link(socket, dt, _) do
    live_redirect "#{dt.name} (#{dt.count})", to: Routes.live_path(socket, DeerStorageWeb.DeerRecordsLive.Index, dt.id), class: "navbar-item"
  end

  def title(conn) do
    case conn.assigns[:title] do
      nil -> gettext("DeerStorage")
      title -> title
    end
  end

  def compact_tables_to_ids_and_names(deer_tables) do
    Enum.map(deer_tables, fn %{id: id, name: name} -> %{id: id, name: name} end)
  end

  def header_text(%{assigns: %{current_subscription_is_expired: true}}), do: gettext("DATABASE EXPIRED")
  def header_text(%{assigns: %{current_subscription: %{name: name}}}), do: name
  def header_text(%{assigns: %{current_user: %{name: name}}}), do: name
  def header_text(_), do: gettext("DeerStorage")

  def render_navigation(%{assigns: %{current_user: nil}} = conn), do: render "navigation_guest.html", conn: conn
  def render_navigation(%{assigns: %{current_user: %{role: "admin"}, current_subscription: nil}} = conn) do
    render "navigation_admin.html", conn: conn
  end
  def render_navigation(conn), do: render "navigation_user.html", conn: conn
end
