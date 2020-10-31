defmodule PjeskiWeb.DeerRecordsLive.Index.SocketAssigns.Records do
  import Phoenix.LiveView, only: [assign: 2, assign: 3, push_redirect: 2]
  import PjeskiWeb.LiveHelpers, only: [is_expired?: 1]
  import Pjeski.DbHelpers.DeerRecordsSearch, only: [search_records: 4]
  import PjeskiWeb.DeerRecordsLive.Index.SocketAssigns.Helpers, only: [reduce_list_with_function: 2, try_to_replace_record: 2]

  def change_page(%{assigns: %{query: query}} = socket, new_page), do: run_search_query_and_assign_results(socket, query, new_page)

  def assign_records_after_update(%{assigns: %{current_subscription: %{id: subscription_id}, table_id: table_id, query: query, page: page, records: records}} = socket, updated_record) do
    new_records = try_to_replace_record(records, updated_record) || search_records(subscription_id, table_id, query, page)

    assign(socket, records: new_records, count: length(new_records))
  end

  def assign_records_and_count_after_delete(%{assigns: %{records: []}} = socket, _), do: socket
  def assign_records_and_count_after_delete(%{assigns: %{records: records}} = socket, id) when is_number(id) do
    new_records = reduce_list_with_function(records, fn record -> unless(id == record.id, do: record) end)
    assign(socket, records: new_records, count: length(new_records))
  end

  def assign_records_and_count_after_delete(%{assigns: %{records: records}} = socket, ids) when is_list(ids) do
    new_records = reduce_list_with_function(records, fn record -> unless(Enum.member?(ids, record.id), do: record) end)
    assign(socket, records: new_records, count: length(new_records))
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
end
