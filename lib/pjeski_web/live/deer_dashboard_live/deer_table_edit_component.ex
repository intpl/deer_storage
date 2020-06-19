defmodule PjeskiWeb.DeerDashboardLive.DeerTableEditComponent do
  use Phoenix.LiveComponent

  import PjeskiWeb.Gettext
  # import Phoenix.HTML.Form

  def render(%{table: %{id: _table_id, name: table_name, deer_columns: _deer_columns}} = assigns) do
    ~L"""
    <p>
      <strong><%= table_name %></strong>
      <a phx-click="cancel_edit" phx-target="<%= @myself %>"><%= gettext("Cancel") %></a>
      <br>
      EDITING...
    </p>
    """
  end

  def handle_event("cancel_edit", _, socket) do
    send self(), :cancel_edit
    {:noreply, socket}
  end
end
