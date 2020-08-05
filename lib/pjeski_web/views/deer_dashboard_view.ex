defmodule PjeskiWeb.DeerDashboardView do
  use PjeskiWeb, :view

  def render_table_show_component(socket, table, editing_table_id) do
    live_component(
      socket,
      PjeskiWeb.DeerDashboardLive.DeerTableShowComponent,
      id: "#{table.id}",
      table: table,
      editing_table_id: editing_table_id
    )
  end

  def render_table_edit_component(socket, table, editing_table_changeset) do
    live_component(
      socket,
      PjeskiWeb.DeerDashboardLive.DeerTableEditComponent,
      id: "#{table.id}",
      table: table,
      changeset: editing_table_changeset,
      show_add_column: true
    )
  end
end
