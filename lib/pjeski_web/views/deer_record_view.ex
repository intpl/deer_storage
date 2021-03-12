defmodule PjeskiWeb.DeerRecordView do
  use PjeskiWeb, :view

  import Ecto.Changeset, only: [fetch_field!: 2]

  alias Pjeski.DeerRecords.DeerRecord
  alias Pjeski.Subscriptions.Subscription

  def empty?(nil), do: true
  def empty?(""), do: true
  def empty?(_), do: false

  def maybe_join_query(""), do: ""
  def maybe_join_query(list) when is_list(list), do: Enum.join(list, " ")

  def maybe_shrink_filename(text, limit \\ 17)
  def maybe_shrink_filename(text, limit) when byte_size(text) > limit do
    half_limit = trunc(limit / 2)
    String.slice(text, 0..(half_limit)) <> "..." <> String.slice(text, -(half_limit)..-1)
  end
  def maybe_shrink_filename(text, _), do: text

  def compare_downcased_strings(nil, _), do: false
  def compare_downcased_strings(_, nil), do: false
  def compare_downcased_strings("", _), do: false
  def compare_downcased_strings(_, ""), do: false
  def compare_downcased_strings(str1, str2), do: String.downcase(str1) =~ String.downcase(str2)

  def render_prepared_fields(prepared_fields), do: render(PjeskiWeb.DeerRecordView, "_editable_prepared_fields.html", prepared_fields: prepared_fields)

  def mimetype_is_previewable?("image/jpeg"), do: true
  def mimetype_is_previewable?("image/png"), do: true
  def mimetype_is_previewable?("image/gif"), do: true
  def mimetype_is_previewable?(_), do: false

  def prepare_fields_for_form(deer_columns, changeset) do
    deer_fields = Ecto.Changeset.fetch_field!(changeset, :deer_fields)

    deer_columns
    |> Enum.with_index
    |> Enum.map(fn {dc, index} ->
      %{id: dc.id,
        index: index,
        name: dc.name,
        value: Enum.find_value(deer_fields, fn df -> df.deer_column_id == dc.id && df.content end)
       }
    end)
  end

  def different_deer_fields(%Ecto.Changeset{} = changeset, record), do: different_deer_fields(fetch_field!(changeset, :deer_fields), record.deer_fields)

  def different_deer_fields(deer_fields1, deer_fields2) do
    Enum.reduce(deer_fields1, [], fn %{deer_column_id: column_id, content: content}, acc ->
      deer_field2 = Enum.find(deer_fields2, fn df -> df.deer_column_id == column_id end)

      case deer_field2.content != content do
        true -> acc ++ [column_id]
        false -> acc
      end
    end)
  end

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

  def deer_table_name_from_id(deer_tables, table_id) do
    Enum.find(deer_tables, fn table -> table.id == table_id end).name
  end

  def deer_field_content_from_column_id(%DeerRecord{deer_fields: deer_fields}, column_id), do: deer_field_content_from_column_id(deer_fields, column_id)
  def deer_field_content_from_column_id(deer_fields, column_id) when is_list(deer_fields) do
    case Enum.find(deer_fields, fn field -> field.deer_column_id == column_id end) do
      nil -> nil
      field -> field.content
    end
  end

  def deer_columns_from_subscription(%Subscription{deer_tables: deer_tables}, table_id) do
    Enum.find(deer_tables, fn table -> table.id == table_id end).deer_columns
  end

  def deer_table_from_subscription(nil, _table_id), do: nil
  def deer_table_from_subscription(%Subscription{deer_tables: []}, _table_id), do: nil
  def deer_table_from_subscription(%Subscription{deer_tables: deer_tables}, table_id) do
    Enum.find(deer_tables, fn table -> table.id == table_id end)
  end

  def classes_for_record_box(user_id, record, opened_records) do
    case Enum.find(opened_records, fn [%{id: id}, _connected_records] -> record.id == id end) do
      nil -> "has-background-light has-text-link is-clickable"
      %{user_id: ^user_id} -> "has-background-white has-text-link is-clickable"
      _ -> "has-background-link has-text-white is-clickable"
    end
  end
end
