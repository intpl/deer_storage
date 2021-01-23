defmodule PjeskiWeb.DeerRecordsLive.Index.SocketAssigns.ConnectingRecords do
  import Pjeski.DbHelpers.DeerRecordsSearch, only: [search_records: 4]
  import PjeskiWeb.DeerRecordsLive.Index.SocketAssigns.Helpers, only: [
    reduce_list_with_function: 2,
    try_to_replace_record: 2,
    find_record_in_list_or_database: 4
  ]

  import Phoenix.LiveView, only: [assign: 2, assign: 3]
  import Pjeski.DeerRecords, only: [connect_records!: 3, remove_orphans_from_connected_records!: 2]

  def assign_connected_records_after_update(%{assigns: %{connecting_record: nil}} = socket, _), do: socket
  def assign_connected_records_after_update(
    %{assigns: %{
         current_subscription: %{id: subscription_id},
         connecting_selected_table_id: table_id,
         connecting_query: query,
         connecting_records: records
      }} = socket, updated_record) do

    # TODO pagination

    new_records = try_to_replace_record(records, updated_record) || search_records(subscription_id, table_id, query, 1) # change page

    assign(socket, connecting_records: new_records) # add count
  end

  def assign_connecting_records_after_delete(%{assigns: %{connecting_records: []}} = socket, _), do: socket
  def assign_connecting_records_after_delete(%{assigns: %{connecting_record: %{id: id}}} = socket, id), do: assign_closed_connecting_records(socket)
  def assign_connecting_records_after_delete(%{assigns: %{connecting_records: records}} = socket, id) when is_number(id) do
    new_records = reduce_list_with_function(records, fn record -> unless(id == record.id, do: record) end)
    assign(socket, connecting_records: new_records)
  end

  def assign_connecting_records_after_delete(%{assigns: %{connecting_records: records, connecting_record: %{id: connecting_record_id}}} = socket, ids) when is_list(ids) do
    case Enum.member?(ids, connecting_record_id) do
      true -> assign_closed_connecting_records(socket)
      false ->
        assign(
          socket,
          :connecting_records,
          reduce_list_with_function(records, fn record -> unless(Enum.member?(ids, record.id), do: record) end)
        )
    end
  end

  def assign_closed_connecting_records(socket), do: assign(socket, connecting_record: nil, connecting_records: [], connecting_query: nil)

  def assign_filtered_connected_records(%{assigns: %{current_subscription: subscription, connecting_selected_table_id: old_table_id}} = socket, query, new_table_id) when byte_size(query) <= 50 do
    if new_table_id != old_table_id, do: Enum.find(subscription.deer_tables, fn %{id: id} -> id == new_table_id end) || raise("invalid table id")

    assign(socket,
      connecting_query: query,
      connecting_records: search_records(subscription.id, new_table_id, query, 1),
      connecting_selected_table_id: new_table_id
    )
  end

  def handle_connecting_records(%{assigns: %{opened_records: opened_records, connecting_record: connecting_record, connecting_records: connecting_records, current_subscription: subscription}} = socket, selected_record_id) do
    [record1, _connected_records] = Enum.find(opened_records, fn [record, _connected_records] -> record.id == connecting_record.id end)
    record2 = Enum.find(connecting_records, fn record -> record.id == selected_record_id end)

    connect_records!(record1, record2, subscription.id)

    assign(socket, connecting_record: nil, connecting_query: nil, connecting_records: [])
  end

  def assign_modal_for_connecting_records(%{assigns: %{records: records, current_subscription: subscription, table_id: table_id}} = socket, record_id) do
    record = find_record_in_list_or_database(subscription, records, record_id, table_id)
    table_id = List.first(subscription.deer_tables).id
    connecting_record_records = search_records(subscription.id, table_id, "", 1)

    socket |> assign(
      connecting_record: record,
      connecting_records: connecting_record_records,
      connecting_selected_table_id: table_id)
  end

  def remove_orphans_after_receiveing_connected_records(socket, record, records) do
    remove_orphans_from_connected_records!(record, records)

    socket
  end
end
