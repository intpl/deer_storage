defmodule PjeskiWeb.Admin.DashboardLive.Index do
  use Phoenix.LiveView

  alias Pjeski.Users
  alias Pjeski.Subscriptions

  def mount(_params, %{"pjeski_auth" => token}, socket) do
    #if connected?(socket), do: :timer.send_interval(30000, self(), :update)

    if connected?(socket), do: Users.subscribe

    {:ok, assign(socket, token: token)}
  end

  def render(assigns) do
    ~L"""
    <section class="hero is-large is-dark">
      <div class="hero-body">
        <div class="container">
          <p class="title">
            Subscriptions: <%= assigns.subscriptions_count %><br>
          </p>
          <p class="subtitle">
            Users: <%= assigns.users_count %>
          </p>
          <p class="subtitle">
          (reloads <b>LIVE</b>!)
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
