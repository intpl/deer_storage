defmodule Pjeski.FeatureFlags do
  def registration_enabled?, do: System.get_env("FEATURE_REGISTRATION") == "1"
  def promote_first_user_to_admin_enabled?, do: System.get_env("FEATURE_AUTOCONFIRM_AND_PROMOTE_FIRST_USER_TO_ADMIN") == "1"
  def mailing_enabled? do
    result = present_env?("POW_MAILGUN_BASE_URI") &&
    present_env?("POW_MAILGUN_DOMAIN") &&
    present_env?("POW_MAILGUN_API_KEY")

    !!result
  end

  def mailing_disabled? do
    result = empty_env?("POW_MAILGUN_BASE_URI") ||
    empty_env?("POW_MAILGUN_DOMAIN") ||
    empty_env?("POW_MAILGUN_API_KEY")

    !!result
  end

  defp empty_env?(env_string), do: empty?(System.get_env(env_string))
  defp present_env?(env_string), do: present?(System.get_env(env_string))

  defp empty?(""), do: true
  defp empty?(nil), do: true
  defp empty?(_), do: false

  defp present?(""), do: false
  defp present?(nil), do: false
  defp present?(_), do: true

end
