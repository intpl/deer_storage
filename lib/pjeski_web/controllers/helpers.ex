defmodule PjeskiWeb.Controllers.Helpers do
  alias PjeskiWeb.Router.Helpers, as: Routes

  def dashboard_path_for(:user), do: Routes.live_path(PjeskiWeb.Endpoint, PjeskiWeb.DashboardLive.Index)
  def dashboard_path_for(:admin), do: Routes.admin_live_path(PjeskiWeb.Endpoint, PjeskiWeb.Admin.DashboardLive.Index)
  def dashboard_path_for(role) when is_bitstring(role), do: role |> String.to_atom |> dashboard_path_for
end
