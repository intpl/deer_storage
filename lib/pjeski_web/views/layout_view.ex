defmodule PjeskiWeb.LayoutView do
  use PjeskiWeb, :view

  def build_title_for_user(%{displayed_name: name}) when not is_nil(name) do
    name <> " - " <> gettext("Clinic Management System")
  end

  def build_title_for_user(_user) do
    gettext("Clinic Management System")
  end

  def build_header_for_user(%{displayed_name: name}) when not is_nil(name) do
    name |> prepend_emoji
  end

  def build_header_for_user(_user) do
    gettext("Clinic Management System") |> prepend_emoji
  end

  defp prepend_emoji(string) do
    "🐶 " <> string # pretty dog emoji
  end
end
