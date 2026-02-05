defmodule DeerStorageWeb.DeerRecordsLive.Index.SocketAssigns.NewRecord do
  alias DeerStorage.DeerRecords.DeerRecord
  import Phoenix.Component, only: [assign: 2]

  import DeerStorageWeb.DeerRecordsLive.Index.SocketAssigns.Helpers,
    only: [atomize_and_merge_table_id_to_attrs: 2]

  import DeerStorage.DeerRecords, only: [change_record: 3, check_limits_and_create_record: 3]

  def assign_opened_new_record_modal(
        %{
          assigns: %{
            current_subscription: %{deer_tables: deer_tables} = subscription,
            table_id: table_id
          }
        } = socket
      ) do
    deer_columns = Enum.find(deer_tables, fn table -> table.id == table_id end).deer_columns

    deer_fields_attrs =
      Enum.map(deer_columns, fn %{id: column_id} -> %{deer_column_id: column_id, content: ""} end)

    assign(socket,
      new_record:
        change_record(subscription, %DeerRecord{}, %{
          deer_table_id: table_id,
          deer_fields: deer_fields_attrs
        })
    )
  end

  def assign_created_record(
        %{
          assigns: %{
            current_subscription: subscription,
            table_id: table_id,
            cached_count: cached_count
          }
        } = socket,
        attrs
      ) do
    atomized_attrs = atomize_and_merge_table_id_to_attrs(attrs, table_id)

    case check_limits_and_create_record(subscription, atomized_attrs, cached_count) do
      {:ok, _} -> assign(socket, new_record: nil, query: [])
      {:error, %Ecto.Changeset{} = changeset} -> assign(socket, new_record: changeset)
    end
  end

  def assign_new_record(
        %{
          assigns: %{
            current_subscription: subscription,
            table_id: table_id,
            new_record: new_record
          }
        } = socket,
        attrs
      ) do
    socket
    |> assign(
      new_record:
        change_record(
          subscription,
          new_record,
          atomize_and_merge_table_id_to_attrs(attrs, table_id)
        )
    )
  end
end
