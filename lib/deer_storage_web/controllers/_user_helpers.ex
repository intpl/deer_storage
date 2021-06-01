defmodule DeerStorageWeb.ControllerHelpers.UserHelpers do
  use DeerStorageWeb, :controller

  def redirect_to_dashboard(%{assigns: %{current_user: %{role: "admin"}}} = conn, nil) do
    conn |> redirect(to: Routes.admin_live_path(conn, DeerStorageWeb.Admin.DashboardLive.Index))
  end
  def redirect_to_dashboard(conn, _), do: conn |> redirect(to: Routes.live_path(conn, DeerStorageWeb.DeerDashboardLive.Index))
end
