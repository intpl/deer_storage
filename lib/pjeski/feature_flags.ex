defmodule Pjeski.FeatureFlags do
  def registration_enabled?, do: System.get_env("FEATURE_REGISTRATION") == "1"
  def promote_first_user_to_admin_enabled?, do: System.get_env("FEATURE_AUTOCONFIRM_AND_PROMOTE_USER_TO_ADMIN") == "1"
end
