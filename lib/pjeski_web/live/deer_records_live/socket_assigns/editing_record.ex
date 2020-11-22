defmodule PjeskiWeb.DeerRecordsLive.Index.SocketAssigns.EditingRecord do
  import Ecto.Changeset, only: [fetch_field!: 2]

  import PjeskiWeb.DeerRecordView, only: [different_deer_fields: 2]
  import Phoenix.LiveView, only: [assign: 2]

  import PjeskiWeb.DeerRecordsLive.Index.SocketAssigns.Helpers, only: [atomize_and_merge_table_id_to_attrs: 2, append_missing_fields_to_record: 3, overwrite_deer_fields: 2]
  import Pjeski.DeerRecords, only: [change_record: 3, update_record: 3]

  import Ecto.Changeset, only: [fetch_field!: 2]

  def assign_closed_editing_record(socket), do: assign(socket, editing_record: nil, editing_record_has_been_removed: false, old_editing_record: nil)

  def assign_editing_record_after_update(%{assigns: %{editing_record: %{data: %{id: record_id}} = old_editing_record_changeset, current_subscription: subscription, table_id: table_id}} = socket, %{id: record_id} = record_in_database) do
    ch = overwrite_deer_fields(record_in_database, fetch_field!(old_editing_record_changeset, :deer_fields))
    new_editing_record_changeset = change_record(subscription, ch, %{deer_table_id: table_id})
    socket = assign(socket, editing_record: new_editing_record_changeset)

    case Enum.any?(different_deer_fields(new_editing_record_changeset, record_in_database)) do
      true -> assign(socket, old_editing_record: change_record(subscription, record_in_database, %{deer_table_id: table_id}))
      false -> socket
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

    case update_record(subscription, record.data, atomized_attrs) do
      {:ok, _} -> assign(socket, editing_record: nil, old_editing_record: nil)
      {:error, _} -> socket
    end
  end

  def assign_editing_record(%{assigns: %{current_subscription: subscription, table_id: table_id, editing_record: editing_record}} = socket, attrs) do
    socket |> assign(editing_record: change_record(subscription, editing_record, atomize_and_merge_table_id_to_attrs(attrs, table_id)))
  end

  def copy_editing_record_to_new_record(%{assigns: %{editing_record: %Ecto.Changeset{} = editing_record, new_record: nil}} = socket) do
    socket |> assign(new_record: editing_record) |> assign_closed_editing_record
  end

  defp assign_error_editing_record_removed(socket), do: assign(socket, editing_record_has_been_removed: true)
end
