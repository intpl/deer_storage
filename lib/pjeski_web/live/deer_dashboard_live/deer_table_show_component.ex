defmodule PjeskiWeb.DeerDashboardLive.DeerTableShowComponent do
  use Phoenix.LiveComponent

  import PjeskiWeb.Gettext

  def render(%{table: %{id: table_id, name: table_name, deer_columns: deer_columns}} = assigns) do
    ~L"""
    <p>
      <strong><%= table_name %></strong>

      <%= if @editing_table_id == nil do %>
        <a phx-click="toggle_edit" phx-value-table_id="<%= table_id %>" phx-target="<%= @myself %>"><%= gettext("Edit") %></a>
      <% end %>

      <br>

      <%= for %{name: name} <- deer_columns do %>
        <%= name %><br>
      <% end %>
    </p>
    """
  end

  def handle_event("toggle_edit", %{"table_id" => table_id}, socket) do
    send self(), {:toggle_edit, table_id}
    {:noreply, socket}
  end
end
