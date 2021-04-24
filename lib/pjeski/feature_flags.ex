defmodule Pjeski.FeatureFlags do
  def registration_enabled?, do: System.get_env("FEATURE_REGISTRATION") == "1"
end
