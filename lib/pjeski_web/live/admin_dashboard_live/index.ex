defmodule PjeskiWeb.Admin.DashboardLive.Index do
  use Phoenix.LiveView
  alias Phoenix.PubSub

  import PjeskiWeb.Gettext

  alias Pjeski.Users
  alias Pjeski.Subscriptions

  def mount(%{}, %{"pjeski_auth" => token, "locale" => locale, "current_user_id" => current_user_id}, socket) do
    socket = case connected?(socket) do
               true ->
                 # TODO: Renewing tokens
                 PubSub.subscribe(Pjeski.PubSub, "Users")
                 PubSub.subscribe(Pjeski.PubSub, "session_#{token}")
                 PubSub.subscribe(Pjeski.PubSub, "user_#{current_user_id}")
                 fetch(socket)
               false -> socket |> assign(users_count: "", subscriptions_count: "")
             end

    Gettext.put_locale(locale)

    {:ok, assign(socket, token: token)}
  end

  def render(assigns) do
    ~L"""
    <section class="hero is-large is-dark">
      <div class="hero-body">
        <div class="container">
          <p class="title">
            <%= gettext("Subscriptions") %>: <%= @subscriptions_count %><br>
          </p>
          <p class="subtitle">
            <%= gettext("Users") %>: <%= @users_count %>
          </p>
        </div>
      </div>
    </section>
    """
  end

  defp fetch(socket) do
    users = Users.total_count
    subscriptions = Subscriptions.total_count

    socket |> assign(users_count: users, subscriptions_count: subscriptions)
  end

  def handle_info({[:user | _], _}, socket), do: {:noreply, socket |> fetch}

  # TODO: determine if this can actually be intercepted as it only calls window.location in JS
  def handle_info(:logout, socket), do: {:noreply, push_redirect(socket, to: "/")}

  # TODO: renew tokens
end
