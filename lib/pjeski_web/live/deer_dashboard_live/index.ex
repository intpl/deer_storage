defmodule PjeskiWeb.DeerDashboardLive.Index do
  use Phoenix.LiveView

  import Pjeski.Users.UserSessionUtils, only: [get_live_user: 2]

  alias Pjeski.Repo
  alias Pjeski.UserAvailableSubscriptionLinks.UserAvailableSubscriptionLink

  def mount(_params, %{"pjeski_auth" => token, "current_subscription_id" => subscription_id} = session, socket) do
    #if connected?(socket), do: :timer.send_interval(30000, self(), :update)
    user = get_live_user(socket, session)

    Gettext.put_locale(user.locale)

    {:ok, socket |> assign(
        current_user: user,
        current_subscription_id: subscription_id,
        token: token,
        editing_table_id: nil
      )}
  end

  def handle_params(_params, _, %{assigns: %{current_user: user, current_subscription_id: subscription_id}} = socket) do
    case connected?(socket) do
      true ->
        user_subscription_link = Repo.get_by!(UserAvailableSubscriptionLink, [user_id: user.id, subscription_id: subscription_id])
        |> Repo.preload(:subscription)
        subscription = user_subscription_link.subscription

        {:noreply, socket |> assign(
            current_subscription_name: subscription.name,
            current_subscription_tables: subscription.deer_tables,
            user_subscription_link: user_subscription_link) # TODO: permissions
        }
      false -> {:noreply, socket |> assign(current_subscription_name: "", current_subscription_tables: [])}
    end
  end

  def handle_info(:cancel_edit, socket), do: {:noreply, socket |> assign(editing_table_id: nil)}
  def handle_info({:toggle_edit, table_id}, socket) do
    {:noreply, socket |> assign(editing_table_id: table_id)}
  end


  def handle_params(_, _, socket), do: {:noreply, socket}

  def render(assigns), do: PjeskiWeb.DeerDashboardView.render("index.html", assigns)
end
