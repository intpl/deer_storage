defmodule PjeskiWeb.DeerDashboardLive.Index do
  use Phoenix.LiveView

  import Pjeski.Users.UserSessionUtils, only: [get_live_user: 2]
  import PjeskiWeb.LiveHelpers, only: [keys_to_atoms: 1]
  import PjeskiWeb.Gettext

  import Pjeski.Subscriptions, only: [update_deer_table!: 3, create_deer_table!: 3, update_subscription: 2]

  alias Phoenix.PubSub
  alias Pjeski.Repo
  alias Pjeski.UserAvailableSubscriptionLinks.UserAvailableSubscriptionLink
  alias Pjeski.Subscriptions.DeerTable

  def mount(_params, %{"pjeski_auth" => _token, "current_subscription_id" => nil}, socket), do: {:ok, push_redirect(socket, to: "/registration/edit")}
  def mount(_params, %{"pjeski_auth" => token, "current_subscription_id" => subscription_id} = session, socket) do
    #if connected?(socket), do: :timer.send_interval(30000, self(), :update)
    if connected?(socket), do: PubSub.subscribe(Pjeski.PubSub, "subscription:#{subscription_id}")

    user = get_live_user(socket, session)

    Gettext.put_locale(user.locale)

    {:ok, socket |> assign(
        current_user: user,
        current_subscription_id: subscription_id,
        token: token,
        editing_subscription_name: false,
        editing_table_id: nil
      )}
  end

  def handle_event("save_subscription_name", %{"name" => new_name}, %{assigns: %{current_subscription: subscription}} = socket) do
    update_subscription(subscription, %{name: new_name})

    {:noreply, socket |> assign(editing_subscription_name: false)}
  end

  def handle_event("toggle_edit_subscription_name", %{}, %{assigns: %{editing_subscription_name: bool}} = socket) do
    {:noreply, socket |> assign(editing_subscription_name: !bool, editing_table_id: nil)}
  end

  def handle_event("add_table", %{}, %{assigns: %{current_subscription: subscription}} = socket) do
    case create_deer_table!(subscription, gettext("New table"), [gettext("Example column 1")]) do
      {:error, subscription_changeset} ->
        invalid_changeset = subscription_changeset.changes.deer_tables |> Enum.find(fn dt -> dt.valid? == false end)

        {:noreply, socket |> assign(editing_table_changeset: invalid_changeset)}
      {:ok, updated_subscription} -> {:noreply, socket |> assign(
                                       current_subscription: updated_subscription,
                                       current_subscription_tables: updated_subscription.deer_tables
                                       )}
    end
  end # {:noreply, assign(socket, :editing_table_id, nil)}

  def handle_event("cancel_edit", _, socket), do: {:noreply, assign(socket, :editing_table_id, nil)}
  def handle_event("validate_edit", _, socket), do: {:noreply, socket} # TODO
  def handle_event("save_edit", %{"deer_table" => attrs}, %{assigns: %{current_subscription: subscription}} = socket) do
    {deer_table_attrs, deer_table_id} = attrs_to_deer_table(attrs)

    case update_deer_table!(subscription, deer_table_id, deer_table_attrs) do
      {:error, subscription_changeset} ->
        invalid_changeset = subscription_changeset.changes.deer_tables |> Enum.find(fn dt -> dt.data.id == deer_table_id end)

        {:noreply, socket |> assign(editing_table_changeset: invalid_changeset)}
      {:ok, updated_subscription} -> {:noreply, socket |> assign(
                                       editing_subscription_name: false,
                                       editing_table_id: nil,
                                       editing_table_changeset: nil,
                                       current_subscription: updated_subscription,
                                       current_subscription_tables: updated_subscription.deer_tables
                                       )}
    end
  end

  def handle_info({:subscription_updated, subscription}, socket) do
    {:noreply, socket |> assign(
        editing_subscription_name: false,
        current_subscription_tables: subscription.deer_tables,
        current_subscription_name: subscription.name,
        current_subscription: subscription,
        editing_table_id: nil
      )}
  end

  def handle_info({:toggle_edit, table_id}, %{assigns: %{current_subscription: subscription}} = socket) do
    changeset = subscription.deer_tables |> Enum.find(fn dt -> dt.id == table_id end) |> DeerTable.changeset(%{})

    {:noreply, socket |> assign(editing_table_id: table_id, editing_table_changeset: changeset, editing_subscription_name: false)}
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
