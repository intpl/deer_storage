defmodule PjeskiWeb.LayoutView do
  use PjeskiWeb, :view

  import Pjeski.Users.UserSessionUtils, only: [get_current_subscription_id_from_conn: 1]

  def title(conn) do
    case conn.assigns[:title] do
      nil -> gettext("StorageDeer")
      title -> title
    end
  end

  def render_navigation(%{assigns: %{navigation_template_always: template}} = conn), do: render template, conn: conn
  def render_navigation(%{assigns: %{navigation_template_when_logged_out: template, current_user: nil}} = conn), do: render template, conn: conn
  def render_navigation(%{assigns: %{navigation_template_when_logged_in: template}} = conn), do: render template, conn: conn

  def render_navigation(%{assigns: %{current_user: nil}} = conn), do: render "navigation_guest.html", conn: conn
  def render_navigation(%{assigns: %{current_user: %{role: "user"}}} = conn), do: render "navigation_user.html", conn: conn
  def render_navigation(%{assigns: %{current_user: %{role: "admin"}}} = conn) do
    case get_current_subscription_id_from_conn(conn) do
      nil -> render "navigation_admin.html", conn: conn
      _ -> render "navigation_user.html", conn: conn
    end
  end
end
