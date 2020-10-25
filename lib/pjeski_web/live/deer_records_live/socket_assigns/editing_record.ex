defmodule PjeskiWeb.DeerRecordsLive.Index.SocketAssigns.EditingRecord do
  import Ecto.Changeset, only: [fetch_field!: 2, change: 2]

  alias Pjeski.DeerRecords.DeerField

  import PjeskiWeb.DeerRecordView, only: [compare_deer_fields_from_changeset_with_record: 2]
  import Phoenix.LiveView, only: [assign: 2, assign: 3]

  import PjeskiWeb.DeerRecordsLive.Index.SocketAssigns.Helpers, only: [atomize_and_merge_table_id_to_attrs: 2]
  import Pjeski.DeerRecords, only: [change_record: 3, update_record: 3]

  import Ecto.Changeset, only: [fetch_field!: 2, change: 2]
  import Phoenix.LiveView, only: [assign: 2]

  def assign_closed_editing_record(socket), do: assign(socket, editing_record: nil, editing_record_has_been_removed: false, editing_record_has_been_updated_data: nil)

  def assign_editing_record_after_update(%{assigns: %{editing_record: %{data: %{id: record_id}} = editing_record}} = socket, %{id: record_id} = updated_record) do
    case Enum.any?(compare_deer_fields_from_changeset_with_record(editing_record, updated_record)) do
      true -> assign_error_editing_record_updated(socket, updated_record)
      false ->
        deer_fields = fetch_field!(editing_record, :deer_fields)
        changeset = change(updated_record, %{deer_fields: deer_fields})

        assign(socket, editing_record: changeset)
    end
  end

  def assign_editing_record_after_update(socket, _record), do: socket

  def assign_editing_record_after_delete(%{assigns: %{editing_record: nil}} = socket, _), do: socket
  def assign_editing_record_after_delete(%{assigns: %{editing_record: %{data: %{id: id}}}} = socket, id), do: assign_error_editing_record_removed(socket)
  def assign_editing_record_after_delete(%{assigns: %{editing_record: editing_record}} = socket, ids) when is_list(ids) do
    case Enum.member?(ids, fetch_field!(editing_record, :id)) do
      true -> assign_error_editing_record_removed(socket)
      false -> socket
    end
  end

  def assign_editing_record_after_delete(socket, id) when is_number(id), do: socket

  def assign_opened_edit_record_modal(%{assigns: %{opened_records: opened_records, current_subscription: subscription, table_id: table_id}} = socket, record_id) do
    id = record_id |> String.to_integer
    [record, _] = Enum.find(opened_records, fn [record, _connected_records] -> record.id == id end)

    assign(socket, editing_record: change_record(
          subscription,
          append_missing_fields_to_record(record, table_id, subscription),
          %{deer_table_id: table_id}
        )
    )
  end

  def assign_saved_editing_record(%{assigns: %{editing_record: record, current_subscription: subscription, table_id: table_id}} = socket, attrs) do
    atomized_attrs = atomize_and_merge_table_id_to_attrs(attrs, table_id)

    {:ok, _} = update_record(subscription, record.data, atomized_attrs)
    socket |> assign(
      editing_record: nil,
      editing_record_has_been_updated_data: nil
    )
  end

  def assign_editing_record(%{assigns: %{current_subscription: subscription, table_id: table_id, editing_record: editing_record}} = socket, attrs) do
    socket |> assign(editing_record: change_record(subscription, editing_record, atomize_and_merge_table_id_to_attrs(attrs, table_id)))
  end

  def copy_editing_record_to_new_record(%{assigns: %{editing_record: %Ecto.Changeset{} = editing_record, new_record: nil}} = socket) do
    socket |> assign(new_record: editing_record) |> assign_closed_editing_record
  end

  defp assign_error_editing_record_removed(socket), do: assign(socket, editing_record_has_been_removed: true)
  defp assign_error_editing_record_updated(socket, record), do: assign(socket, editing_record_has_been_updated_data: record)

  defp append_missing_fields_to_record(record, table_id, subscription) do
    table = Enum.find(subscription.deer_tables, fn dt -> dt.id == table_id end)

    table_columns_ids = Enum.map(table.deer_columns, fn dc -> dc.id  end)
    fields_ids = Enum.map(record.deer_fields, fn df -> df.deer_column_id end)
    missing_fields = (table_columns_ids -- fields_ids) |> Enum.map(fn id -> %DeerField{deer_column_id: id, content: nil} end)

    Map.merge(record, %{deer_fields: record.deer_fields ++ missing_fields})
  end
end
