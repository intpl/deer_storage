defmodule Pjeski.DbHelpers.DeerRecordsSearch do
  import Ecto.Query

  alias Pjeski.Repo
  alias Pjeski.DeerRecords.DeerRecord

  def per_page(), do: 30

  def search_records(subscription_id, table_id, query_string, page) do
    initial_query = DeerRecord
    |> where([dr], dr.subscription_id == ^subscription_id and dr.deer_table_id == ^table_id)
    |> offset(^calculate_offset(page))
    |> limit(^per_page())
    |> order_by(desc: :updated_at)

    query = case query_string do
      nil -> initial_query
      "" -> initial_query
      _ ->
        initial_query
        |> where(^recursive_dynamic_query(query_string |> String.replace("*", "%") |> String.split))
    end

    Repo.all(query)
  end

  defp recursive_dynamic_query([head| []]), do: dynamic(^recursive_dynamic_query(head))
  defp recursive_dynamic_query([head | tail]), do: dynamic(^recursive_dynamic_query(head) and ^recursive_dynamic_query(tail))
  defp recursive_dynamic_query(word) do
    dynamic([q], fragment("exists (select * from unnest(?) obj where obj->>'content' ilike ?)", field(q, :deer_fields), ^"%#{word}%"))
  end

  defp calculate_offset(page) when page > 0, do: (page - 1) * per_page()
end
