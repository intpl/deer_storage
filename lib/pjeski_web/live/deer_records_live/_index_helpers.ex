defmodule PjeskiWeb.DeerRecordsLive.Index.Helpers do
  alias Pjeski.UserAvailableSubscriptionLinks.UserAvailableSubscriptionLink
  alias Phoenix.PubSub
  alias Pjeski.Repo

  alias Pjeski.SharedRecords
  alias Pjeski.DeerRecords.DeerRecord
  alias Pjeski.DeerRecords.DeerField

  import PjeskiWeb.DeerRecordView, only: [deer_table_from_subscription: 2, compare_deer_fields_from_changeset_with_record: 2]
  import PjeskiWeb.LiveHelpers, only: [is_expired?: 1, keys_to_atoms: 1]
  import Ecto.Changeset, only: [fetch_field!: 2, change: 2]

  import Pjeski.DeerRecords, only: [
    batch_delete_records: 3,
    change_record: 3,
    check_limits_and_create_record: 3,
    connect_records!: 3,
    delete_file_from_record!: 3,
    delete_record: 2,
    disconnect_records!: 3,
    get_record!: 2,
    get_records!: 2,
    update_record: 3
  ]

  import Pjeski.DbHelpers.DeerRecordsSearch, only: [per_page: 0, search_records: 4]
  import Phoenix.LiveView, only: [assign: 2, assign: 3, push_redirect: 2]

  def change_page(%{assigns: %{query: query}} = socket, new_page), do: run_search_query_and_assign_results(socket, query, new_page)

  def assign_editing_record_after_update(%{assigns: %{editing_record: %{data: %{id: record_id}} = editing_record}} = socket, %{id: record_id} = updated_record) do
    case Enum.any?(compare_deer_fields_from_changeset_with_record(editing_record, updated_record)) do
      true -> assign_error_editing_record_updated(socket, updated_record)
      false ->
        deer_fields = fetch_field!(editing_record, :deer_fields)
        changeset = change(updated_record, %{deer_fields: deer_fields})

        assign_editing_record_changeset(socket, changeset)
    end
  end

  def assign_editing_record_after_update(socket, _record), do: socket

  def assign_currently_connected_records_after_update(%{assigns: %{currently_connecting_record_id: nil}} = socket, _), do: socket
  def assign_currently_connected_records_after_update(
    %{assigns: %{
         current_subscription: %{id: subscription_id},
         currently_connecting_record_selected_table_id: table_id,
         currently_connecting_record_query: query,
         currently_connecting_record_records: records
      }} = socket, updated_record) do

    # TODO pagination

    new_records = try_to_replace_record(records, updated_record) || search_records(subscription_id, table_id, query, 1) # change page

    assign(socket, currently_connecting_record_records: new_records) # add count
  end

  def assign_records_after_update(%{assigns: %{current_subscription: %{id: subscription_id}, table_id: table_id, query: query, page: page, records: records}} = socket, updated_record) do
    new_records = try_to_replace_record(records, updated_record) || search_records(subscription_id, table_id, query, page)

    assign(socket, records: new_records, count: length(new_records))
  end

  def assign_opened_records_after_update(%{assigns: %{opened_records: []}} = socket, _), do: socket
  def assign_opened_records_after_update(%{assigns: %{opened_records: opened_records}} = socket, %{id: updated_record_id} = updated_record) do
    new_opened_records = reduce_opened_records_with_function(opened_records, fn record ->
      case record.id do
        ^updated_record_id ->
          maybe_send_assign_connected_records(record, updated_record)

          updated_record
        _ -> record
      end
    end)

    assign(socket, opened_records: new_opened_records)
  end


  def assign_closed_editing_record(socket), do: assign(socket, editing_record: nil, editing_record_has_been_removed: false, editing_record_has_been_updated_data: nil)

  def copy_editing_record_to_new_record(%{assigns: %{editing_record: %Ecto.Changeset{} = editing_record, new_record: nil}} = socket) do
    socket |> assign(new_record: editing_record)
  end

  def assign_editing_record_after_delete(%{assigns: %{editing_record: nil}} = socket, _), do: socket
  def assign_editing_record_after_delete(%{assigns: %{editing_record: %{data: %{id: id}}}} = socket, id), do: assign_error_editing_record_removed(socket)
  def assign_editing_record_after_delete(%{assigns: %{editing_record: editing_record}} = socket, ids) when is_list(ids) do
    case Enum.member?(ids, fetch_field!(editing_record, :id)) do
      true -> assign_error_editing_record_removed(socket)
      false -> socket
    end
  end

  def assign_editing_record_after_delete(socket, id) when is_number(id), do: socket

  def assign_records_and_count_after_delete(%{assigns: %{records: []}} = socket, _), do: socket
  def assign_records_and_count_after_delete(%{assigns: %{records: records}} = socket, id) when is_number(id) do
    new_records = reduce_list_with_function(records, fn record -> unless(id == record.id, do: record) end)
    assign(socket, records: new_records, count: length(new_records))
  end

  def assign_records_and_count_after_delete(%{assigns: %{records: records}} = socket, ids) when is_list(ids) do
    new_records = reduce_list_with_function(records, fn record -> unless(Enum.member?(ids, record.id), do: record) end)
    assign(socket, records: new_records, count: length(new_records))
  end

  def assign_opened_records_after_delete(%{assigns: %{opened_records: []}} = socket, _), do: socket
  def assign_opened_records_after_delete(%{assigns: %{opened_records: opened_records}} = socket, id) when is_number(id) do
    assign(socket, opened_records: reduce_opened_records_with_function(opened_records, fn record -> unless(id == record.id, do: record) end))
  end

  def assign_opened_records_after_delete(%{assigns: %{opened_records: opened_records}} = socket, ids) when is_list(ids) do
    assign(socket, opened_records: reduce_opened_records_with_function(opened_records, fn record -> unless(Enum.member?(ids, record.id), do: record) end))
  end

  def assign_currently_connecting_records_and_count_after_delete(%{assigns: %{currently_connecting_record_records: []}} = socket, _), do: socket
  def assign_currently_connecting_records_and_count_after_delete(%{assigns: %{currently_connecting_record_records: records}} = socket, id) when is_number(id) do
    new_records = reduce_list_with_function(records, fn record -> unless(id == record.id, do: record) end)
    assign(socket, currently_connecting_record_records: new_records)
  end

  def assign_currently_connecting_records_and_count_after_delete(%{assigns: %{currently_connecting_record_records: records}} = socket, ids) when is_list(ids) do
    new_records = reduce_list_with_function(records, fn record -> unless(Enum.member?(ids, record.id), do: record) end)
    assign(socket, currently_connecting_record_records: new_records)
  end

  def maybe_delete_records_from_list_by_ids(list, ids) do
    Enum.reject(list, fn %{id: id} -> Enum.member?(ids, id) end)
  end

  def maybe_delete_record_from_list_by_id(list, record_id) do
    case Enum.find_index(list, fn %{id: id} -> record_id == id end) do
      nil -> list
      idx -> List.delete_at(list, idx)
    end
  end

  def update_opened_record_with_connected_records(list, id, connected_records) do
    case Enum.find_index(list, fn [%{id: record_id}, _old_connected_record] -> id == record_id end) do
      nil -> list # this is neccessary due to race condition after toggling two times quickly
      idx ->
        [record, _old_connected_records] = Enum.at(list, idx)
        List.replace_at(list, idx, [record, connected_records])
    end
  end

  def toggle_opened_record_in_list([], opened_record), do: [opened_record]
  def toggle_opened_record_in_list(list, [%{id: record_id}, _] = opened_record) do
    case Enum.find_index(list, fn [%{id: id}, _connected_records] -> record_id == id end) do
      nil -> [opened_record | list]
      idx ->  List.delete_at(list, idx)
    end
  end

  def reduce_opened_records_with_function(opened_records, function) do
    Enum.reduce(opened_records, [], fn [record, connected_records], acc_list ->
      case function.(record) do
        nil -> acc_list
        reduced_record -> acc_list ++ [
            [reduced_record, reduce_list_with_function(connected_records, function)]
          ]
      end
    end)
  end

  def reduce_list_with_function(list, function) do
    Enum.reduce(list, [], fn item, acc_list ->
      case function.(item) do
        nil -> acc_list
        reduced_item -> acc_list ++ [reduced_item]
      end
    end)
  end

  def maybe_update_opened_record_in_list(list, [record, _connected_records] = opened_record) do
    case Enum.find_index(list, fn [%{id: id}, _connected_records] -> record.id == id end) do
      nil -> list
      idx -> List.replace_at(list, idx, opened_record)
    end
  end

  def maybe_delete_opened_record_from_list(list, record_id) do
    case Enum.find_index(list, fn [%{id: id}, _] -> record_id == id end) do
      nil -> list
      idx -> List.delete_at(list, idx)
    end
  end

  def append_missing_fields_to_record(record, table_id, subscription) do
    table = Enum.find(subscription.deer_tables, fn dt -> dt.id == table_id end)

    table_columns_ids = Enum.map(table.deer_columns, fn dc -> dc.id  end)
    fields_ids = Enum.map(record.deer_fields, fn df -> df.deer_column_id end)
    missing_fields = (table_columns_ids -- fields_ids) |> Enum.map(fn id -> %DeerField{deer_column_id: id, content: nil} end)

    Map.merge(record, %{deer_fields: record.deer_fields ++ missing_fields})
  end

  def handle_delete_all_opened_records(%{assigns: %{opened_records: opened_records, current_subscription: subscription, table_id: table_id}} = socket) do
    ids = Enum.map(opened_records, fn [record, _connected_records] -> record.id end)
    {:ok, _deleted_count} = batch_delete_records(subscription, table_id, ids)

    socket
  end

  def handle_delete_record(%{assigns: %{records: records, current_subscription: subscription}} = socket, record_id) do
    record = find_record_in_list_or_database(subscription, records, record_id)
    {:ok, _} = delete_record(subscription, record)

    socket
  end

  def assign_opened_edit_record_modal(%{assigns: %{records: records, current_subscription: subscription, table_id: table_id}} = socket, record_id) do
    record = find_record_in_list_or_database(subscription, records, record_id)
    |> append_missing_fields_to_record(table_id, subscription)

    assign(socket, editing_record: change_record(subscription, record, %{deer_table_id: table_id}))
  end

  def assign_opened_new_record_modal(%{assigns: %{current_subscription: %{deer_tables: deer_tables} = subscription, table_id: table_id}} = socket) do
    deer_columns = Enum.find(deer_tables, fn table -> table.id == table_id end).deer_columns
    deer_fields_attrs = Enum.map(deer_columns, fn %{id: column_id} -> %{deer_column_id: column_id, content: ""} end)

    assign(socket, new_record: change_record(subscription, %DeerRecord{}, %{deer_table_id: table_id, deer_fields: deer_fields_attrs}))
  end

  def assign_filtered_connected_records(%{assigns: %{current_subscription: subscription, currently_connecting_record_selected_table_id: old_table_id}} = socket, query, new_table_id) when byte_size(query) <= 50 do
    if new_table_id != old_table_id, do: Enum.find(subscription.deer_tables, fn %{id: id} -> id == new_table_id end) || raise("invalid table id")

    assign(socket,
      currently_connecting_record_query: query,
      currently_connecting_record_records: search_records(subscription.id, new_table_id, query, 1),
      currently_connecting_record_selected_table_id: new_table_id
    )
  end

  def handle_file_delete(%{assigns: %{current_subscription: %{id: subscription_id}}} = socket, record_id, file_id) do
    delete_file_from_record!(subscription_id, record_id, file_id)

    socket
  end

  def handle_disconnecting_records(%{assigns: %{opened_records: opened_records, current_subscription: subscription}} = socket, record1_id, record2_id) do
    [record1, connected_records] = Enum.find(opened_records, fn [record, _connected_records] -> record.id == record1_id end)
    record2 = Enum.find(connected_records, fn record -> record.id == record2_id end)

    disconnect_records!(record1, record2, subscription.id)

    socket
  end

  def handle_connecting_records(%{assigns: %{opened_records: opened_records, currently_connecting_record_id: currently_connecting_record_id, currently_connecting_record_records: connecting_record_records, current_subscription: subscription}} = socket, selected_record_id) do
    [record1, _connected_records] = Enum.find(opened_records, fn [record, _connected_records] -> record.id == currently_connecting_record_id end)
    record2 = Enum.find(connecting_record_records, fn record -> record.id == selected_record_id end)

    connect_records!(record1, record2, subscription.id)

    assign(socket, currently_connecting_record_id: nil, currently_connecting_record_query: nil, currently_connecting_record_records: [])
  end

  def assign_created_shared_record_uuid(%{assigns: %{records: records, current_user: user, current_subscription: subscription}} = socket, record_id) do
    record = find_record_in_list_or_database(subscription, records, record_id) # todo: traverse connected_records instead
    %{id: uuid} = SharedRecords.create_record!(subscription.id, user.id, record.id)
    assign(socket, current_shared_record_uuid: uuid)
  end

  def assign_opened_record_and_fetch_connected_records(%{assigns: %{records: records, opened_records: opened_records, current_subscription: subscription}} = socket, record_id) when length(opened_records) < 50 do
    record = find_record_in_list_or_database(subscription, records, record_id)
    opened_records = toggle_opened_record_in_list(opened_records, [record, []])

    send(self(), {:assign_connected_records_to_record, record.id, record.connected_deer_records_ids})

    assign(socket, opened_records: opened_records)
  end

  def assign_connected_records_to_record(%{assigns: %{current_subscription: subscription, opened_records: opened_records}} = socket, record_id, ids) do
    new_opened_records = update_opened_record_with_connected_records(opened_records, record_id, get_records!(subscription.id, ids))

    assign(socket, opened_records: new_opened_records)
  end

  def assign_saved_record(%{assigns: %{current_subscription: subscription, table_id: table_id, cached_count: cached_count}} = socket, attrs) do
    atomized_attrs = atomize_and_merge_table_id_to_attrs(attrs, table_id)

    case check_limits_and_create_record(subscription, atomized_attrs, cached_count) do
      {:ok, _} -> assign(socket, new_record: nil, query: "")
      {:error, %Ecto.Changeset{} = changeset} -> assign(socket, new_record: changeset)
    end
  end

  def assign_updated_record(%{assigns: %{editing_record: record, current_subscription: subscription, table_id: table_id}} = socket, attrs) do
    atomized_attrs = atomize_and_merge_table_id_to_attrs(attrs, table_id)

    {:ok, _} = update_record(subscription, record.data, atomized_attrs)
    socket |> assign(
      editing_record: nil,
      editing_record_has_been_updated_data: nil
    )
  end

  def assign_new_record(%{assigns: %{current_subscription: subscription, table_id: table_id, new_record: new_record}} = socket, attrs) do
    socket |> assign(new_record: change_record(subscription, new_record, atomize_and_merge_table_id_to_attrs(attrs, table_id)))
  end

  def assign_editing_record(%{assigns: %{current_subscription: subscription, table_id: table_id, editing_record: editing_record}} = socket, attrs) do
    socket |> assign(editing_record: change_record(subscription, editing_record, atomize_and_merge_table_id_to_attrs(attrs, table_id)))
  end

  def assign_modal_for_connecting_records(%{assigns: %{records: records, current_subscription: subscription}} = socket, record_id) do
    record = find_record_in_list_or_database(subscription, records, record_id)
    table_id = List.first(subscription.deer_tables).id
    connecting_record_records = search_records(subscription.id, table_id, "", 1)

    socket |> assign(
      currently_connecting_record_id: record.id,
      currently_connecting_record_records: connecting_record_records,
      currently_connecting_record_selected_table_id: table_id)
  end

  def assign_first_search_query_if_subscription_is_not_expired(%{assigns: %{current_subscription: subscription, table_id: table_id}} = socket, query) do
    case is_expired?(subscription) do
      true -> push_redirect(socket, to: "/registration/edit")
      false ->
        socket
        |> run_search_query_and_assign_results(query, 1)
        |> assign(:cached_count, DeerCache.RecordsCountsCache.fetch_count(table_id))
    end
  end

  def run_search_query_and_assign_results(%{assigns: %{current_subscription: %{id: subscription_id}, table_id: table_id}} = socket, query, page) do
    records = search_records(subscription_id, table_id, query, page)

    socket |> assign(count: length(records), query: query, records: records, page: page)
  end

  def assign_table_or_redirect_to_dashboard!(%{assigns: %{current_subscription: subscription}} = socket, table_id) do
    case table_from_subscription(subscription, table_id) do
      %{name: table_name} -> assign(socket, table_name: table_name, table_id: table_id)
      nil -> push_redirect(socket, to: "/dashboard")
    end
  end

  def assign_subscription_if_available_subscription_link_exists!(socket, user_id, subscription_id) do
    user_subscription_link = UserAvailableSubscriptionLink
    |> Repo.get_by!([user_id: user_id, subscription_id: subscription_id])
    |> Repo.preload(:subscription)

    assign_subscription(socket, user_subscription_link.subscription)
  end

  def assign_updated_subscription(%{assigns: %{editing_record: editing_record, new_record: new_record, table_id: table_id}} = socket, subscription) do
    case is_expired?(subscription) do
      true -> push_redirect(socket, to: "/registration/edit")
      false ->
        case deer_table_from_subscription(subscription, table_id) do
          nil -> push_redirect(socket, to: "/dashboard")
          %{name: table_name} ->
            socket
            |> assign(:table_name, table_name)
            |> assign_subscription(subscription)
            |> maybe_assign_record_changeset(:new_record, subscription, new_record)
            |> maybe_assign_record_changeset(:editing_record, subscription, editing_record)
       end
     end
  end

  def assign_subscription(socket, subscription) do
    assign(socket,
      current_subscription: subscription,
      current_subscription_name: subscription.name,
      current_subscription_tables: subscription.deer_tables,
      current_subscription_deer_records_per_table_limit: subscription.deer_records_per_table_limit,
      storage_limit_kilobytes: subscription.storage_limit_kilobytes
    )
  end

  def assign_initial_mount_data(socket, user, current_subscription_id) do
    assign(socket,
      opened_records: [],
      editing_record: nil,
      editing_record_has_been_removed: false,
      editing_record_has_been_updated_data: nil,
      new_record: nil,
      table_name: nil,
      page: 1,
      per_page: per_page(),
      cached_count: 0,
      current_user: user,
      current_subscription: nil,
      current_subscription_id: current_subscription_id,
      current_subscription_name: nil,
      current_subscription_tables: [],
      current_subscription_deer_records_per_table_limit: 0,
      current_shared_record_uuid: nil,
      currently_connecting_record_id: nil,
      currently_connecting_record_query: nil,
      currently_connecting_record_records: [],
      currently_connecting_record_selected_table_id: nil,
      storage_limit_kilobytes: 0,
      locale: user.locale
    )
  end

  def subscribe_to_user_channels(token, user_id) do
    PubSub.subscribe(Pjeski.PubSub, "session_#{token}")
    PubSub.subscribe(Pjeski.PubSub, "user_#{user_id}")
  end

  def subscribe_to_deer_channels(subscription_id, table_id) do
    PubSub.subscribe(Pjeski.PubSub, "record:#{subscription_id}:#{table_id}")
    PubSub.subscribe(Pjeski.PubSub, "subscription:#{subscription_id}")
    PubSub.subscribe(Pjeski.PubSub, "records_counts:#{table_id}")
  end

  defp assign_editing_record_changeset(socket, %Ecto.Changeset{} = changeset), do: assign(socket, editing_record: changeset)

  defp assign_error_editing_record_removed(socket), do: assign(socket, editing_record_has_been_removed: true)
  defp assign_error_editing_record_updated(socket, record), do: assign(socket, editing_record_has_been_updated_data: record)

  defp table_from_subscription(%{deer_tables: deer_tables}, table_id) do
    Enum.find(deer_tables, fn deer_table -> deer_table.id == table_id end)
  end

  defp find_record_in_list_or_database(subscription, records, id) do
    id = id |> String.to_integer

    Enum.find(records, fn record -> record.id == id end) || get_record!(subscription, id)
  end

  defp atomize_and_merge_table_id_to_attrs(attrs, table_id), do: Map.merge(attrs, %{"deer_table_id" => table_id}) |> keys_to_atoms

  defp maybe_send_assign_connected_records(%DeerRecord{connected_deer_records_ids: list}, %DeerRecord{connected_deer_records_ids: list}), do: nil
  defp maybe_send_assign_connected_records(_old_record, %DeerRecord{connected_deer_records_ids: connected_records_ids} = new_record) do
    send(self(), {:assign_connected_records_to_record, new_record.id, connected_records_ids})
  end

  defp maybe_assign_record_changeset(socket, _type, _subscription, nil), do: socket
  defp maybe_assign_record_changeset(socket, assign_key, subscription, %{data: %{deer_table_id: table_id}} = record) do
    assign(socket, assign_key, change_record(subscription, record, %{deer_table_id: table_id}))
  end

  defp try_to_replace_record(records, updated_record) do
    case Enum.find_index(records, fn %{id: id} -> updated_record.id == id end) do
      nil -> nil
      idx -> List.replace_at(records, idx, updated_record)
    end
  end
end
