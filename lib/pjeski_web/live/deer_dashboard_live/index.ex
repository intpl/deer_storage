defmodule PjeskiWeb.DeerDashboardLive.Index do
  use Phoenix.LiveView

  @tmp_dir System.tmp_dir!()

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
    create_deer_tables!: 2,
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
        all_listed_examples: nil,
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
    case create_deer_table!(subscription, gettext("Example table"), [gettext("Example column 1")]) do
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

  def handle_event("validate_table_edit", %{"deer_table" => attrs}, %{assigns: %{editing_table_changeset: ch}} = socket) do
    {deer_table_attrs, _id} = attrs_to_deer_table(attrs)

    {:noreply, socket |> assign(editing_table_changeset: DeerTable.changeset(ch, deer_table_attrs))}
  end

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

  def handle_event("use_example", %{"key" => key}, %{assigns: %{current_subscription: subscription}} = socket) do
    {_title, _description, tables} = Pjeski.DeerTablesExamples.show(key)

    case create_deer_tables!(subscription, tables) do
      {:error, _subscription_changeset} ->
        {:noreply,
          assign(socket, displayed_error: gettext("Your subscription limits do not allow to use this template. Please contact the Administrator to exceed limits."))}
      {:ok, updated_subscription} ->
        for %{id: id} <- updated_subscription.deer_tables do
          PubSub.subscribe(Pjeski.PubSub, "records_counts:#{id}")
        end

        {:noreply, socket |> assign(
          current_subscription: updated_subscription,
          current_subscription_tables: updated_subscription.deer_tables
        )}
    end
  end

  def handle_event("reset_displayed_error", _, socket), do: {:noreply, assign(socket, displayed_error: nil)}

  def handle_event("validate_upload", _, socket), do: {:noreply, socket}
  def handle_event("submit_upload", _, %{assigns: %{current_subscription: subscription, current_user: user}} = socket) do
    consume_uploaded_entries(socket, :csv_file, fn %{path: path}, %{client_name: original_filename, uuid: uuid} ->
      tmp_path = Path.join(@tmp_dir, uuid)
      File.cp!(path, tmp_path)

      spawn(Pjeski.CsvImporter, :run!, [subscription, user, tmp_path, original_filename, uuid, true])
    end)

    {:noreply, socket}
  end

  def handle_info({:subscription_updated, %{deer_tables: new_tables} = subscription}, %{assigns: %{current_subscription: %{deer_tables: old_tables}}} = socket) do
    case is_expired?(subscription) do
      true -> {:noreply, push_redirect(socket, to: "/registration/edit")}
      false -> {:noreply, socket
      |> handle_cache_for_new_tables(old_tables, new_tables)
      |> assign(editing_subscription_name: false,
                current_subscription_tables: subscription.deer_tables,
                current_subscription_name: subscription.name,
                storage_limit_kilobytes: subscription.storage_limit_kilobytes,
                subscription_deer_tables_limit: subscription.deer_tables_limit,
                subscription_deer_records_per_table_limit: subscription.deer_records_per_table_limit,
                subscription_deer_columns_per_table_limit: subscription.deer_columns_per_table_limit,
                current_subscription: subscription,
                editing_table_id: nil
                ) |> assign_examples_if_no_subscription_tables}
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

        available_tables_count = subscription.deer_tables_limit - length(subscription.deer_tables)

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
              user_subscription_link: user_subscription_link)
              |> assign_examples_if_no_subscription_tables
              |> allow_upload(:csv_file, accept: ~w(.csv), auto_upload: true, max_entries: available_tables_count)}
        end

      false -> {:noreply, socket |> assign(current_subscription_name: "", current_subscription_tables: nil)}
    end
  end

  def handle_params(_, _, socket), do: {:noreply, socket}

  def render(%{current_subscription_tables: []} = assigns), do: PjeskiWeb.DeerDashboardView.render("examples_index.html", assigns)
  def render(assigns), do: PjeskiWeb.DeerDashboardView.render("editable_deer_tables.html", assigns)

  defp handle_cache_for_new_tables(%{assigns: %{cached_counts: cached_counts}} = socket, old_tables, new_tables) do
    new_tables = list_new_table_ids(old_tables, new_tables)

    Enum.each(new_tables, fn id ->
      PubSub.subscribe(Pjeski.PubSub, "records_counts:#{id}")
    end)

    new_cached_counts = Enum.reduce(new_tables, cached_counts, fn table_id, inner_cached_counts ->
      Map.merge(inner_cached_counts, %{table_id => DeerCache.RecordsCountsCache.fetch_count(table_id)})
    end)

    assign(socket, cached_counts: new_cached_counts)
  end

  defp attrs_to_deer_table(attrs) do
    attrs_without_deer_columns = keys_to_atoms(Map.delete(attrs, "deer_columns"))

    deer_columns = attrs["deer_columns"]
    |> Enum.map(fn {idx_string, dc} -> {String.to_integer(idx_string), dc} end)
    |> Enum.sort(&(first_tuple_element(&1) < first_tuple_element(&2)))
    |> Enum.map(fn {_idx, dc} -> dc end)
    |> Enum.map(fn deer_column -> keys_to_atoms(deer_column) end)

    deer_table = Map.merge(%{deer_columns: deer_columns}, attrs_without_deer_columns)

    {deer_table, attrs["id"]}
  end

  defp first_tuple_element({el, _}), do: el

  defp assign_examples_if_no_subscription_tables(%{assigns: %{current_subscription_tables: []}} = socket) do
    assign(socket, all_listed_examples: Pjeski.DeerTablesExamples.list_examples())
  end

  defp assign_examples_if_no_subscription_tables(socket), do: socket
end
