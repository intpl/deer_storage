defmodule PjeskiWeb.DeerDashboardLive.Index do
  use Phoenix.LiveView

  import Pjeski.Users.UserSessionUtils, only: [get_live_user: 2]
  import PjeskiWeb.LiveHelpers, only: [keys_to_atoms: 1]

  import Pjeski.Subscriptions, only: [update_deer_table!: 3]

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

  def handle_event("cancel_edit", _, socket), do: {:noreply, assign(socket, :editing_table_id, nil)}
  def handle_event("validate_edit", _, socket), do: {:noreply, socket} # TODO
  def handle_event("save_edit", %{"deer_table" => attrs}, %{assigns: %{current_subscription: subscription}} = socket) do
    {deer_table_attrs, deer_table_id} = attrs_to_deer_table(attrs)

    {:ok, updated_subscription} = update_deer_table!(subscription, deer_table_id, deer_table_attrs)

    {:noreply, socket |> assign(
        editing_table_id: nil,
        current_subscription: updated_subscription,
        current_subscription_tables: updated_subscription.deer_tables
      )} # TODO
  end

  def handle_info({:toggle_edit, table_id}, socket) do
    {:noreply, socket |> assign(editing_table_id: table_id)}
  end

  def handle_params(_params, _, %{assigns: %{current_user: user, current_subscription_id: subscription_id}} = socket) do
    case connected?(socket) do
      true ->
        user_subscription_link = Repo.get_by!(UserAvailableSubscriptionLink, [user_id: user.id, subscription_id: subscription_id])
        |> Repo.preload(:subscription)
        subscription = user_subscription_link.subscription

        {:noreply, socket |> assign(
            current_subscription: subscription,
            current_subscription_name: subscription.name,
            current_subscription_tables: subscription.deer_tables,
            user_subscription_link: user_subscription_link) # TODO: permissions
        }
      false -> {:noreply, socket |> assign(current_subscription_name: "", current_subscription_tables: [])}
    end
  end

  def handle_params(_, _, socket), do: {:noreply, socket}

  def render(assigns), do: PjeskiWeb.DeerDashboardView.render("index.html", assigns)

  defp attrs_to_deer_table(attrs) do
    attrs_without_deer_columns = keys_to_atoms(Map.delete(attrs, "deer_columns"))

    deer_columns = attrs["deer_columns"]
    |> Map.values
    |> Enum.map(fn deer_column -> keys_to_atoms(deer_column) end)

    deer_table = Map.merge(%{deer_columns: deer_columns}, attrs_without_deer_columns)

    {deer_table, attrs["id"]}
  end
end
