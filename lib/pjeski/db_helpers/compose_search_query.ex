defmodule Pjeski.DbHelpers.ComposeSearchQuery do
  import Ecto.Query
 
  def compose_search_query(columns, string) do
    filters = string
    |> String.replace("*", "%")
    |> String.split
    |> Enum.map(fn word ->
      wrapped_word = "%#{word}%"
      Keyword.new columns, (fn key -> {key, wrapped_word} end)
    end)

    dynamic(^recursive_dynamic_query(filters))
  end

  defp recursive_dynamic_query([{key, value} | []]), do: dynamic(^recursive_dynamic_query(key, value))
  defp recursive_dynamic_query([arr | []]), do: dynamic(^recursive_dynamic_query(arr))
  defp recursive_dynamic_query([{key, value}|rest]) do
    dynamic(^recursive_dynamic_query(key, value) or ^recursive_dynamic_query(rest))
  end
  defp recursive_dynamic_query([first | rest]) when length(rest) < 5 do
    dynamic(^recursive_dynamic_query(first) and ^recursive_dynamic_query(rest))
  end
  defp recursive_dynamic_query(key, value), do: dynamic([q], ilike(field(q, ^key), ^value))
  defp recursive_dynamic_query(_), do: nil
end
