defmodule PjeskiWeb.PageView do
  use PjeskiWeb, :view

  def dashboard_link(%{assigns: %{current_user: %{role: "admin"}, current_subscription: nil}}) do
    link gettext("Go back to Admin Panel..."), to: Routes.admin_live_path(PjeskiWeb.Endpoint, PjeskiWeb.Admin.DashboardLive.Index), class: "button is-link"
  end

  def dashboard_link(_conn) do
    link gettext("Go back to your database..."), to: Routes.live_path(PjeskiWeb.Endpoint, PjeskiWeb.DeerDashboardLive.Index), class: "button is-link"
  end
end
