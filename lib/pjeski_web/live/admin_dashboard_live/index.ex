defmodule PjeskiWeb.Admin.DashboardLive.Index do
  use Phoenix.LiveView
  use PjeskiWeb.LiveHelpers.RenewTokenHandler

  import PjeskiWeb.Gettext
  import Pjeski.Users.UserSessionUtils, only: [user_from_auth_token: 1]

  alias Pjeski.Users
  alias Pjeski.Subscriptions

  def mount(%{}, %{"pjeski_auth" => token}, socket) do
    user = user_from_auth_token(token)

    if connected?(socket) do
      :timer.send_interval(1200000, self(), :renew_token) # 1200000ms = 20min
      Users.subscribe
    end

    Gettext.put_locale(user.locale)

    {:ok, assign(socket, token: token)}
  end

  def render(assigns) do
    ~L"""
    <section class="hero is-large is-dark">
      <div class="hero-body">
        <div class="container">
          <p class="title">
            <%= gettext("Subscriptions") %>: <%= assigns.subscriptions_count %><br>
          </p>
          <p class="subtitle">
            <%= gettext("Users") %>: <%= assigns.users_count %>
          </p>
        </div>
      </div>
    </section>
    """
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket |> fetch}
  end

  defp fetch(socket) do
    users = Users.total_count
    subscriptions = Subscriptions.total_count

    socket |> assign(users_count: users, subscriptions_count: subscriptions)
  end

  def handle_info({Users, [:user | _], _}, socket) do
    {:noreply, socket |> fetch}
  end
end
