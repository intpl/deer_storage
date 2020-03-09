defmodule Pjeski.LocalePlug do
  import Plug.Conn, only: [assign: 3]

  @default_locale "pl"

  def init(_opts), do: nil

  def call(%Plug.Conn{assigns: %{current_user: %Pjeski.Users.User{locale: locale}}} = conn, _opts) do
    Gettext.put_locale(PjeskiWeb.Gettext, locale)

    assign(conn, :locale, locale)
  end

  def call(conn, _opts) do
    Gettext.put_locale(PjeskiWeb.Gettext, @default_locale)

    assign(conn, :locale, @default_locale)
  end
end
