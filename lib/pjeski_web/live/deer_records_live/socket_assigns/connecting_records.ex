defmodule PjeskiWeb.DeerRecordsLive.Index.SocketAssigns.ConnectingRecords do
  import Pjeski.DbHelpers.DeerRecordsSearch, only: [search_records: 4]
  import PjeskiWeb.DeerRecordsLive.Index.SocketAssigns.Helpers, only: [
    reduce_list_with_function: 2,
    try_to_replace_record: 2,
    find_record_in_list_or_database: 3
  ]

  import Phoenix.LiveView, only: [assign: 2]
  import Pjeski.DeerRecords, only: [
    connect_records!: 3
  ]

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

  def assign_currently_connecting_records_and_count_after_delete(%{assigns: %{currently_connecting_record_records: []}} = socket, _), do: socket
  def assign_currently_connecting_records_and_count_after_delete(%{assigns: %{currently_connecting_record_records: records}} = socket, id) when is_number(id) do
    new_records = reduce_list_with_function(records, fn record -> unless(id == record.id, do: record) end)
    assign(socket, currently_connecting_record_records: new_records)
  end

  def assign_currently_connecting_records_and_count_after_delete(%{assigns: %{currently_connecting_record_records: records}} = socket, ids) when is_list(ids) do
    new_records = reduce_list_with_function(records, fn record -> unless(Enum.member?(ids, record.id), do: record) end)
    assign(socket, currently_connecting_record_records: new_records)
  end

  def assign_filtered_connected_records(%{assigns: %{current_subscription: subscription, currently_connecting_record_selected_table_id: old_table_id}} = socket, query, new_table_id) when byte_size(query) <= 50 do
    if new_table_id != old_table_id, do: Enum.find(subscription.deer_tables, fn %{id: id} -> id == new_table_id end) || raise("invalid table id")

    assign(socket,
      currently_connecting_record_query: query,
      currently_connecting_record_records: search_records(subscription.id, new_table_id, query, 1),
      currently_connecting_record_selected_table_id: new_table_id
    )
  end

  def handle_connecting_records(%{assigns: %{opened_records: opened_records, currently_connecting_record_id: currently_connecting_record_id, currently_connecting_record_records: connecting_record_records, current_subscription: subscription}} = socket, selected_record_id) do
    [record1, _connected_records] = Enum.find(opened_records, fn [record, _connected_records] -> record.id == currently_connecting_record_id end)
    record2 = Enum.find(connecting_record_records, fn record -> record.id == selected_record_id end)

    connect_records!(record1, record2, subscription.id)

    assign(socket, currently_connecting_record_id: nil, currently_connecting_record_query: nil, currently_connecting_record_records: [])
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
end
