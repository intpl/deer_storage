defmodule PjeskiWeb.DeerRecordView do
  use PjeskiWeb, :view

  alias Pjeski.DeerRecords.DeerRecord
  alias Pjeski.Subscriptions.Subscription

  def deer_column_name_from_id(deer_columns, column_id) do
    Enum.find(deer_columns, fn column -> column.id == column_id end).name
  end

  def deer_field_content_from_column_id(%DeerRecord{deer_fields: deer_fields}, column_id) do
    Enum.find(deer_fields, fn field -> field.deer_column_id == column_id end).content
  end

  def deer_columns_from_subscription(%Subscription{deer_tables: deer_tables}, table_id) do
    Enum.find(deer_tables, fn table -> table.id == table_id end).deer_columns
  end

  def classes_for_record_box(_, %{id: record_id}, %{id: record_id}), do: "has-background-link has-text-white"
  def classes_for_record_box(current_user_id, %{user_id: current_user_id}, _), do: "has-background-white has-text-link is-clickable"
  def classes_for_record_box(_, _, _), do: "has-background-light has-text-link is-clickable"
end
