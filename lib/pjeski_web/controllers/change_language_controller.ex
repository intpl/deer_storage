defmodule PjeskiWeb.ChangeLanguageController do
  use PjeskiWeb, :controller

  def change_language(conn, %{"locale" => locale}) do
    known_locales = Gettext.known_locales(PjeskiWeb.Gettext)

    if Enum.member?(known_locales, locale),
      do: put_locale_to_session_and_redirect_back(conn, locale),
      else: raise("unsupported locale requested")
  end

  defp put_locale_to_session_and_redirect_back(conn, locale) do
    conn
    |> Plug.Conn.put_session(:locale, locale)
    |> redirect(to: NavigationHistory.last_path(conn, default: "/"))
  end
end
