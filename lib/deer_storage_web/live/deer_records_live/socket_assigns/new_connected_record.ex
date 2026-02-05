defmodule DeerStorageWeb.DeerRecordsLive.Index.SocketAssigns.NewConnectedRecord do
  alias DeerStorage.DeerRecords.DeerRecord
  import Phoenix.Component, only: [assign: 2, assign: 3]

  import DeerStorageWeb.DeerRecordsLive.Index.SocketAssigns.Helpers,
    only: [atomize_and_merge_table_id_to_attrs: 2, find_record_in_opened_records: 2]

  import DeerStorage.DeerRecords,
    only: [change_record: 3, check_limits_and_create_record: 3, connect_records!: 3]

  def maybe_close_new_connected_record_modal(
        %{assigns: %{new_record_connecting_with_record_id: id}} = socket,
        id
      )
      when is_number(id), do: assign_closed_new_connected_record_modal(socket)

  def maybe_close_new_connected_record_modal(
        %{assigns: %{new_record_connecting_with_record_id: id}} = socket,
        ids
      )
      when is_list(ids) do
    if Enum.member?(ids, id), do: assign_closed_new_connected_record_modal(socket), else: socket
  end

  def maybe_close_new_connected_record_modal(socket, _), do: socket

  def assign_closed_new_connected_record_modal(socket),
    do: assign(socket, new_record_connecting_with_record_id: nil, new_record: nil)

  def assign_opened_new_connected_record_modal(
        %{
          assigns: %{
            opened_records: opened_records,
            current_subscription: %{deer_tables: [%{id: first_table_id} | _]}
          }
        } = socket,
        connecting_with_record_id
      ) do
    [%{id: ^connecting_with_record_id}, _connected_records] =
      find_record_in_opened_records(opened_records, connecting_with_record_id)

    assign(socket, :new_record_connecting_with_record_id, connecting_with_record_id)
    |> assign_overwritten_table_id_in_new_record(first_table_id)
  end

  def assign_created_connected_record(
        %{
          assigns: %{
            new_record: new_record,
            opened_records: opened_records,
            new_record_connecting_with_record_id: connecting_with_record_id,
            current_subscription: subscription,
            cached_count: cached_count
          }
        } = socket,
        attrs
      ) do
    [connecting_with_record, _connected_records] =
      find_record_in_opened_records(opened_records, connecting_with_record_id)

    atomized_attrs =
      atomize_and_merge_table_id_to_attrs(
        attrs,
        Ecto.Changeset.fetch_field!(new_record, :deer_table_id)
      )

    {:ok, socket} =
      DeerStorage.Repo.transaction(fn ->
        case check_limits_and_create_record(subscription, atomized_attrs, cached_count) do
          {:ok, created_record} ->
            connect_records!(created_record, connecting_with_record, subscription.id)
            assign_closed_new_connected_record_modal(socket)

          {:error, %Ecto.Changeset{} = changeset} ->
            assign(socket, new_record: changeset)
        end
      end)

    socket
  end

  def assign_overwritten_table_id_in_new_record(
        %{
          assigns: %{
            current_subscription: %{deer_tables: deer_tables} = subscription,
            new_record_connecting_with_record_id: record_id
          }
        } = socket,
        table_id
      )
      when is_number(record_id) do
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

  def assign_new_connected_record(
        %{assigns: %{current_subscription: subscription, new_record: new_record}} = socket,
        attrs
      ) do
    new_attrs =
      atomize_and_merge_table_id_to_attrs(
        attrs,
        Ecto.Changeset.fetch_field!(new_record, :deer_table_id)
      )

    socket |> assign(new_record: change_record(subscription, new_record, new_attrs))
  end
end
