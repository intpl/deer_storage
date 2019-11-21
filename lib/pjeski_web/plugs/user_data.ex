defmodule Pjeski.UserData do
  alias Pjeski.Users.User
  alias Pjeski.Subscriptions

  @default_locale "pl"

  def init(_opts), do: nil

  def call(conn, _opts) do
    user = Pow.Plug.current_user(conn)

    conn_with_locale_and_subscription(conn, user)
  end

  defp conn_with_locale_and_subscription(conn, nil) do
    Gettext.put_locale(PjeskiWeb.Gettext, @default_locale)
    %{conn | assigns: Map.merge(conn.assigns, %{locale: @default_locale, subscription: nil})}
  end

  defp conn_with_locale_and_subscription(conn, %User{subscription_id: nil} = user) do
    conn_with_locale_and_subscription(conn, user.locale, nil)
  end

  defp conn_with_locale_and_subscription(conn, %User{subscription_id: subscription_id} = user) do
    conn_with_locale_and_subscription(conn, user.locale, Subscriptions.get_subscription!(subscription_id))
  end

  defp conn_with_locale_and_subscription(conn, locale, subscription) do
    locale = Atom.to_string(locale)
    Gettext.put_locale(PjeskiWeb.Gettext, locale)

    %{conn | assigns: Map.merge(conn.assigns, %{current_user_locale: locale, current_user_subscription: subscription})}
  end
end
