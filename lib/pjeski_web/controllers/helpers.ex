defmodule PjeskiWeb.Controllers.Helpers do
  alias PjeskiWeb.Router.Helpers, as: Routes
  alias Pjeski.Users.User

  def dashboard_path_for(%User{subscription_id: nil, role: "admin"}), do: dashboard_path_for("admin")
  def dashboard_path_for(%User{subscription_id: _, role: "admin"}), do: dashboard_path_for("user")
  def dashboard_path_for(%User{role: role}), do: dashboard_path_for(role)
  def dashboard_path_for("user"), do: Routes.live_path(PjeskiWeb.Endpoint, PjeskiWeb.DashboardLive.Index)
  def dashboard_path_for("admin"), do: Routes.admin_live_path(PjeskiWeb.Endpoint, PjeskiWeb.Admin.DashboardLive.Index)
end
