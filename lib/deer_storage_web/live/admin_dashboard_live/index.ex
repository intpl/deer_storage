defmodule DeerStorageWeb.Admin.DashboardLive.Index do
  use Phoenix.LiveView
  alias Phoenix.PubSub

  import DeerStorage.Users.UserSessionUtils, only: [get_live_user: 2]

  alias DeerStorage.Users
  alias DeerStorage.Subscriptions

  def mount(
        %{},
        %{"deer_storage_auth" => token, "current_user_id" => current_user_id} = session,
        socket
      ) do
    socket =
      case connected?(socket) do
        true ->
          get_live_user(socket, session).locale |> Gettext.put_locale()

          # TODO: Renewing tokens
          PubSub.subscribe(DeerStorage.PubSub, "Users")
          PubSub.subscribe(DeerStorage.PubSub, "session_#{token}")
          PubSub.subscribe(DeerStorage.PubSub, "user_#{current_user_id}")
          fetch(socket)

        false ->
          assign(socket,
            users_count: "",
            subscriptions_count: "",
            disk_data: [],
            root_disk_percentage: 0,
            root_disk_total_size: 0
          )
      end

    {:ok, assign(socket, token: token)}
  end

  def render(assigns), do: DeerStorageWeb.Admin.DashboardView.render("index.html", assigns)

  defp fetch(socket) do
    users = Users.total_count()
    subscriptions = Subscriptions.total_count()

    {_, root_disk_total_size, root_disk_percentage} =
      :disksup.get_disk_data()
      |> Enum.find(fn {mountpoint, _size, _perc} -> mountpoint == ~c"/" end)

    socket
    |> assign(
      users_count: users,
      subscriptions_count: subscriptions,
      root_disk_percentage: root_disk_percentage,
      root_disk_total_size: root_disk_total_size
    )
  end

  def handle_info({[:user | _], _}, socket), do: {:noreply, socket |> fetch}

  def handle_info(:logout, socket), do: {:noreply, push_navigate(socket, to: "/")}

  # TODO: renew tokens
end
