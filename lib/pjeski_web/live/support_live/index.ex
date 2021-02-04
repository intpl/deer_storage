defmodule PjeskiWeb.SupportLive.Index do
  use Phoenix.LiveView
  alias Phoenix.PubSub
  import Pjeski.Users.UserSessionUtils, only: [get_live_user: 2]
  import PjeskiWeb.Gettext

  def mount(_params, %{"pjeski_auth" => token} = session, socket) do
    user = get_live_user(socket, session)

    if connected?(socket) do
      # TODO: Renewing tokens
      PubSub.subscribe(Pjeski.PubSub, "user_#{user.id}")
      PubSub.subscribe(Pjeski.PubSub, "session_#{token}")
    end

    Gettext.put_locale(user.locale)

    {:ok, socket |> assign(current_user: user, token: token, locale: user.locale)}
  end

  def render(assigns), do: PjeskiWeb.SupportView.render("index.html", assigns)
end
