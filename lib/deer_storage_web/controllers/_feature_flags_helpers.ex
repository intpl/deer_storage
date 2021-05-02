defmodule DeerStorageWeb.ControllerHelpers.FeatureFlagsHelpers do
  import Phoenix.Controller, only: [text: 2]

  def wrap_feature_endpoint(true = _flag_is_enabled, _conn, fun), do: fun.()
  def wrap_feature_endpoint(false = _flag_is_disabled, conn, _fun) do
    text(conn, "Feature is disabled")
  end
end
