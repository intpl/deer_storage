defmodule PjeskiWeb.Pow.RegistrationView do
  use PjeskiWeb, :view

  def languages_select_options do
    [
      [gettext("Polish"), "pl"],
      [gettext("English"), "en"],
    ] |> Map.new(fn [k, v] -> {k, v} end)
  end
end
