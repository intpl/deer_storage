defmodule DeerStorage.Subscriptions.Helpers do
  def deer_tables_to_attrs(deer_tables) do
    Enum.map(deer_tables, fn dt ->
      %{
        id: dt.id,
        name: dt.name,
        deer_columns:
          Enum.map(dt.deer_columns, fn dc ->
            %{
              id: dc.id,
              name: dc.name
            }
          end)
      }
    end)
  end

  def overwrite_table_with_attrs(deer_tables, table_id, attrs) do
    Enum.map(deer_tables, fn dt ->
      case dt.id == table_id do
        true -> Map.merge(dt, attrs)
        false -> dt
      end
    end)
  end
end
