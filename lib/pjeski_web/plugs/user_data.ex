defmodule Pjeski.UserData do
  import Plug.Conn

  def init(_opts), do: nil

  def call(conn, _opts) do
    case Pow.Plug.current_user(conn) do
      nil ->
        # Default language Polish
        Gettext.put_locale(PjeskiWeb.Gettext, "pl")
        conn
      user ->
        locale = Atom.to_string(user.locale)

        Gettext.put_locale(PjeskiWeb.Gettext, locale)
        conn |> put_session(:locale, locale)
    end
  end
end
