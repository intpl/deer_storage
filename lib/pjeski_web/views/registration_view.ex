defmodule PjeskiWeb.RegistrationView do
  use PjeskiWeb, :view

  alias Pjeski.Subscriptions
  alias Pjeski.Users.User

  def languages_select_options do
    [
      [gettext("Polish"), "pl"],
      [gettext("English"), "en"],
    ] |> Map.new(fn [k, v] -> {k, v} end)
  end

  def days_to_expire(%User{subscription_id: nil}), do: "???"
  def days_to_expire(%User{subscription_id: subscription_id}) do
    Date.diff Subscriptions.get_subscription!(subscription_id).expires_on, Date.utc_today
  end
end
