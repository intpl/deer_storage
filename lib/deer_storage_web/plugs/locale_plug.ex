defmodule DeerStorageWeb.LocalePlug do
  import Plug.Conn, only: [assign: 3, get_session: 2]

  @default_locale "en"

  def init(_opts), do: nil

  def call(%Plug.Conn{assigns: %{current_user: %DeerStorage.Users.User{locale: locale}}} = conn, _opts), do: put_and_assign_locale(conn, locale)
  def call(conn, _opts) do
    known_locales = Gettext.known_locales(DeerStorageWeb.Gettext)
    session_locale = get_session(conn, "locale")

    if session_locale && Enum.member?(known_locales, session_locale),
      do: put_and_assign_locale(conn, session_locale),
      else: maybe_put_accept_language_locale(conn, known_locales)
  end

  defp maybe_put_accept_language_locale(conn, known_locales) do
    locale = Enum.find(extract_accept_language(conn), fn accepted_locale -> Enum.member?(known_locales, accepted_locale) end)
    if locale, do: put_and_assign_locale(conn, locale), else: put_and_assign_locale(conn, @default_locale)
  end

  defp put_and_assign_locale(conn, locale) do
    Gettext.put_locale(DeerStorageWeb.Gettext, locale)

    assign(conn, :locale, locale)
  end

  def extract_accept_language(conn) do
    case Plug.Conn.get_req_header(conn, "accept-language") do
      [value | _] ->
        value
        |> String.split(",")
        |> Enum.map(&parse_language_option/1)
        |> Enum.sort(&(&1.quality > &2.quality))
        |> Enum.map(& &1.tag)
        |> Enum.reject(&is_nil/1)
        |> ensure_language_fallbacks()

      _ -> []
    end
  end

  defp parse_language_option(string) do
    captures = Regex.named_captures(~r/^\s?(?<tag>[\w\-]+)(?:;q=(?<quality>[\d\.]+))?$/i, string)

    quality =
      case Float.parse(captures["quality"] || "1.0") do
        {val, _} -> val
        _ -> 1.0
      end

    %{tag: captures["tag"], quality: quality}
  end

  defp ensure_language_fallbacks(tags) do
    Enum.flat_map(tags, fn tag ->
      [language | _] = String.split(tag, "-")
      if Enum.member?(tags, language), do: [tag], else: [tag, language]
    end)
  end

end
