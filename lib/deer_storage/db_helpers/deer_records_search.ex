defmodule DeerStorage.DbHelpers.DeerRecordsSearch do
  import Ecto.Query

  alias DeerStorage.Repo
  alias DeerStorage.DeerRecords.DeerRecord

  def per_page(), do: 30

  def prepare_search_query(""), do: []
  def prepare_search_query(nil), do: []

  def prepare_search_query(query_string) do
    query_string
    |> String.replace("%", "\\%")
    |> String.replace("*", "%")
    |> String.split()
  end

  def search_records(subscription_id, table_id, query_list, page) when is_list(query_list) do
    initial_query =
      DeerRecord
      |> where([dr], dr.subscription_id == ^subscription_id and dr.deer_table_id == ^table_id)
      |> offset(^calculate_offset(page))
      |> limit(^per_page())
      |> order_by(desc: :updated_at)

    query =
      case query_list do
        [] -> initial_query
        _ -> initial_query |> where(^recursive_dynamic_query(query_list))
      end

    Repo.all(query)
  end

  defp recursive_dynamic_query([head | []]), do: dynamic(^recursive_dynamic_query(head))

  defp recursive_dynamic_query([head | tail]),
    do: dynamic(^recursive_dynamic_query(head) and ^recursive_dynamic_query(tail))

  defp recursive_dynamic_query(word) do
    word = "%#{word}%"

    matched_fields =
      dynamic(
        [q],
        fragment(
          "exists (select * from unnest(?) obj where obj->>'content' ilike ?)",
          field(q, :deer_fields),
          ^word
        )
      )

    matched_files =
      dynamic(
        [q],
        fragment(
          "exists (select * from unnest(?) obj where obj->>'original_filename' ilike ?)",
          field(q, :deer_files),
          ^word
        )
      )

    dynamic(^matched_fields or ^matched_files)
  end

  defp calculate_offset(page) when page > 0, do: (page - 1) * per_page()
end
