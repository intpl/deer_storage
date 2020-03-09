defmodule Pjeski.UserDataPlug do
  import Plug.Conn

  alias Plug.Conn
  alias Pjeski.Repo
  alias Pjeski.Users.User

  @default_locale "pl"

  def init(_opts), do: nil

  def call(conn, _opts) do
    # FIXME USE SESSION!!!
    conn = case Pow.Plug.current_user(conn) do
             nil -> conn
             %User{} = user -> assign(conn, :current_user, Repo.preload(user, :subscription))
           end

    # TODO rewrite to use pow_session_metadata
    conn_with_locale(conn)
  end

  defp conn_with_locale(%Conn{assigns: %{current_user: %User{locale: locale}}} = conn) do
    Gettext.put_locale(PjeskiWeb.Gettext, locale)

    assign(conn, :locale, locale)
  end

  defp conn_with_locale(conn) do
    Gettext.put_locale(PjeskiWeb.Gettext, @default_locale)
    assign(conn, :locale, @default_locale)
  end
end
