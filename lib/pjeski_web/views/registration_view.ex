defmodule PjeskiWeb.RegistrationView do
  use PjeskiWeb, :view

  alias Pjeski.Subscriptions
  alias Pjeski.Users.User

  def time_zones_select_options, do: Tzdata.zone_list

  def languages_select_options do
    [
      [gettext("Polish"), "pl"],
      [gettext("English"), "en"],
    ] |> Map.new(fn [k, v] -> {k, v} end)
  end

  def days_to_expire(nil), do: "???"
  def days_to_expire(subscription), do: Date.diff subscription.expires_on, Date.utc_today
end
