defmodule DeerStorageWeb.PageView do
  import DeerStorage.FeatureFlags, only: [registration_enabled?: 0]
  use DeerStorageWeb, :view

  def dashboard_link(%{assigns: %{current_user: %{role: "admin"}, current_subscription: nil}}) do
    link gettext("Go back to Admin Panel..."), to: Routes.admin_live_path(DeerStorageWeb.Endpoint, DeerStorageWeb.Admin.DashboardLive.Index), class: "button is-link"
  end

  def dashboard_link(_conn) do
    link gettext("Go back to your database..."), to: Routes.live_path(DeerStorageWeb.Endpoint, DeerStorageWeb.DeerDashboardLive.Index), class: "button is-link"
  end
end
