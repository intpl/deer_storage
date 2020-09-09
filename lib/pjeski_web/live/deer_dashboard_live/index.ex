defmodule PjeskiWeb.DeerDashboardLive.Index do
  use Phoenix.LiveView

  import Pjeski.Users.UserSessionUtils, only: [get_live_user: 2]
  import PjeskiWeb.LiveHelpers, only: [
    cached_counts: 1,
    is_expired?: 1,
    keys_to_atoms: 1,
    list_new_table_ids: 2
  ]
  import PjeskiWeb.Gettext

  import Pjeski.Subscriptions, only: [
    update_deer_table!: 3,
    create_deer_table!: 3,
    update_subscription: 2,
    delete_deer_table!: 2
  ]
  import Pjeski.Subscriptions.DeerTable, only: [
    add_empty_column: 1,
    move_column_to_index: 3,
  ]

  alias Phoenix.PubSub
  alias Pjeski.Repo
  alias Pjeski.UserAvailableSubscriptionLinks.UserAvailableSubscriptionLink
  alias Pjeski.Subscriptions.DeerTable

  def mount(_params, %{"pjeski_auth" => _token, "current_subscription_id" => nil}, socket), do: {:ok, push_redirect(socket, to: "/registration/edit")}
  def mount(_params, %{"pjeski_auth" => token, "current_subscription_id" => subscription_id} = session, socket) do
    user = get_live_user(socket, session)

    if connected?(socket) do
      # TODO: Renewing tokens
      PubSub.subscribe(Pjeski.PubSub, "user_#{user.id}")
      PubSub.subscribe(Pjeski.PubSub, "subscription:#{subscription_id}")
      PubSub.subscribe(Pjeski.PubSub, "session_#{token}")
    end

    Gettext.put_locale(user.locale)

    {:ok, socket |> assign(
        current_user: user,
        current_subscription_id: subscription_id,
        token: token,
        editing_subscription_name: false,
        editing_table_id: nil,
        storage_limit_kilobytes: 0,
        subscription_deer_tables_limit: 0,
        subscription_deer_records_per_table_limit: 0,
        subscription_deer_columns_per_table_limit: 0,
        locale: user.locale
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
      {:ok, updated_subscription} ->
        created_table = List.last(updated_subscription.deer_tables)
        PubSub.subscribe(Pjeski.PubSub, "records_counts:#{created_table.id}")

        {:noreply, socket |> assign(
            current_subscription: updated_subscription,
            current_subscription_tables: updated_subscription.deer_tables
          )}
    end
  end # {:noreply, assign(socket, :editing_table_id, nil)}

  def handle_event("cancel_table_edit", _, socket), do: {:noreply, assign(socket, editing_table_id: nil, editing_table_changeset: nil)}
  def handle_event("validate_table_edit", _, socket), do: {:noreply, socket} # TODO
  def handle_event("save_table_edit", %{"deer_table" => attrs}, %{assigns: %{current_subscription: subscription}} = socket) do
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

  def handle_event("delete_table", %{"table_id" => table_id}, %{assigns: %{current_subscription: subscription}} = socket) do
    case delete_deer_table!(subscription, table_id) do
      {:error, _subscription} ->
        {:noreply, socket |> assign(editing_table_changeset: nil)}
      {:ok, updated_subscription} -> {:noreply, socket |> assign(
                                       editing_subscription_name: false,
                                       editing_table_id: nil,
                                       editing_table_changeset: nil,
                                       current_subscription: updated_subscription,
                                       current_subscription_tables: updated_subscription.deer_tables
                                       )}
    end
  end

  def handle_event("move_column_up", %{"index" => index}, %{assigns: %{editing_table_changeset: ch}} = socket) do
    index = String.to_integer index
    {:noreply, socket |> assign(editing_table_changeset: move_column_to_index(ch, index, index - 1))}
  end

  def handle_event("move_column_down", %{"index" => index}, %{assigns: %{editing_table_changeset: ch}} = socket) do
    index = String.to_integer index
    {:noreply, socket |> assign(editing_table_changeset: move_column_to_index(ch, index, index + 1))}
  end

  def handle_event("add_column", %{}, %{assigns: %{editing_table_changeset: ch}} = socket) do
    {:noreply, socket |> assign(editing_table_changeset: add_empty_column(ch))}
  end

  def handle_event("toggle_table_edit", %{"table_id" => table_id}, %{assigns: %{current_subscription: subscription}} = socket) do
    changeset = subscription.deer_tables |> Enum.find(fn dt -> dt.id == table_id end) |> DeerTable.changeset(%{})

    {:noreply, socket |> assign(editing_table_id: table_id, editing_table_changeset: changeset, editing_subscription_name: false)}
  end

  def handle_info({:subscription_updated, %{deer_tables: new_tables} = subscription}, %{assigns: %{current_subscription: %{deer_tables: old_tables}}} = socket) do
    list_new_table_ids(old_tables, new_tables)
    |> Enum.each(fn id -> PubSub.subscribe(Pjeski.PubSub, "records_counts:#{id}") end)

    case is_expired?(subscription) do
      true -> {:noreply, push_redirect(socket, to: "/registration/edit")}
      false -> {:noreply, socket |> assign(
        editing_subscription_name: false,
        current_subscription_tables: subscription.deer_tables,
        current_subscription_name: subscription.name,
        storage_limit_kilobytes: subscription.storage_limit_kilobytes,
        subscription_deer_tables_limit: subscription.deer_tables_limit,
        subscription_deer_records_per_table_limit: subscription.deer_records_per_table_limit,
        subscription_deer_columns_per_table_limit: subscription.deer_columns_per_table_limit,
        current_subscription: subscription,
        editing_table_id: nil
      )}
    end
  end

  def handle_info({:cached_records_count_changed, table_id, count}, %{assigns: %{cached_counts: cached_counts}} = socket) do
    {:noreply, socket |> assign(cached_counts: Map.merge(cached_counts, %{table_id => count}))}
  end

  def handle_info(:logout, socket), do: {:noreply, push_redirect(socket, to: "/")}

  def handle_params(_params, _, %{assigns: %{current_user: user, current_subscription_id: subscription_id}} = socket) do
    case connected?(socket) do
      true ->
        user_subscription_link = Repo.get_by!(UserAvailableSubscriptionLink, [user_id: user.id, subscription_id: subscription_id])
        |> Repo.preload(:subscription)
        subscription = user_subscription_link.subscription

        for %{id: id} <- subscription.deer_tables do
          PubSub.subscribe(Pjeski.PubSub, "records_counts:#{id}")
        end

        case is_expired?(subscription) do
          true -> {:noreply, push_redirect(socket, to: "/registration/edit")}
          false -> {
            :noreply,
            socket |> assign(
              cached_counts: cached_counts(subscription.deer_tables),
              current_subscription: subscription,
              current_subscription_name: subscription.name,
              current_subscription_tables: subscription.deer_tables,
              storage_limit_kilobytes: subscription.storage_limit_kilobytes,
              subscription_deer_tables_limit: subscription.deer_tables_limit,
              subscription_deer_records_per_table_limit: subscription.deer_records_per_table_limit,
              subscription_deer_columns_per_table_limit: subscription.deer_columns_per_table_limit,
              user_subscription_link: user_subscription_link
            )} # TODO: permissions
        end

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
