defmodule PjeskiWeb.DeerRecordView do
  use PjeskiWeb, :view

  alias Pjeski.DeerRecords.DeerRecord
  alias Pjeski.Subscriptions.Subscription

  def shared_record_days_to_expire(shared_record) do
    floor(DateTime.diff(shared_record.expires_on, DateTime.utc_now, :second) / 86_400)
  end

  def display_filesize_from_kilobytes(kilobytes) when kilobytes <= 1024, do: "#{kilobytes} KB"
  def display_filesize_from_kilobytes(kilobytes) do
    megabytes = Float.ceil(kilobytes / 1024, 2)

    "#{megabytes} MB"
  end

  def deer_column_name_from_id(deer_columns, column_id) do
    Enum.find(deer_columns, fn column -> column.id == column_id end).name
  end

  def deer_field_content_from_column_id(%DeerRecord{deer_fields: deer_fields}, column_id) do
    case Enum.find(deer_fields, fn field -> field.deer_column_id == column_id end) do
      nil -> nil
      field -> field.content
    end
  end

  def deer_columns_from_subscription(%Subscription{deer_tables: deer_tables}, table_id) do
    Enum.find(deer_tables, fn table -> table.id == table_id end).deer_columns
  end

  def deer_table_from_subscription(%Subscription{deer_tables: []}, _table_id), do: nil
  def deer_table_from_subscription(%Subscription{deer_tables: deer_tables}, table_id) do
    Enum.find(deer_tables, fn table -> table.id == table_id end)
  end

  def classes_for_record_box(user_id, record, current_records) do
    case Enum.find(current_records, fn [%{id: id}, _connected_records] -> record.id == id end) do
      nil -> "has-background-light has-text-link is-clickable"
      %{user_id: ^user_id} -> "has-background-white has-text-link is-clickable"
      _ -> "has-background-link has-text-white is-clickable"
    end
  end
end
