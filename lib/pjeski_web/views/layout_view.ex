defmodule PjeskiWeb.LayoutView do
  use PjeskiWeb, :view

  def request_demo_mailto_href do
    email_address="bgladecki@gmail.com"
    subject="Clinic Management System demo"
    body="Proszę udostępnić mi ten rewelacyjny system do testów!"

    "mailto:" <> email_address <> "?subject=" <> subject <> "&body=" <> body
  end

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
