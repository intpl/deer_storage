defmodule Pjeski.DbHelpers.SearchQuery do
  @moduledoc """
  ## Usage

  ```
  defmodule Users do
    import Ecto.Query, warn: false
    use DbHelpers.SearchQuery, [:name, :email]

    def search(query) do
      Repo.all(from u in User, where: ^compose_search_query(query))
    end
  end
  ```

  ## Examples

  ```
  iex(7)> Users.search("example query")
  SELECT u0."id", ... FROM "users" AS u0 WHERE (((u0."name" ILIKE $1) OR (u0."email" ILIKE $2)) AND ((u0."name" ILIKE $3) OR (u0."email" ILIKE $4))) ["%example%", "%example%", "%query%", "%query%"]
  ```
  """

  defmacro __using__(columns) do
    quote do
      defp compose_search_query(string) do
        filters = string
        |> String.replace("*", "%")
        |> String.split
        |> Enum.uniq
        |> Enum.map(fn word ->
          wrapped_word = "%#{word}%"
          Keyword.new unquote(columns), (fn key -> {key, wrapped_word} end)
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
    end
  end
end
