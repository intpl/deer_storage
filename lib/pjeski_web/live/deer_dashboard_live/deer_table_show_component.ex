defmodule PjeskiWeb.DeerDashboardLive.DeerTableShowComponent do
  alias PjeskiWeb.Router.Helpers, as: Routes
  use Phoenix.LiveComponent

  import PjeskiWeb.Gettext

  def render(%{table: %{id: table_id, name: table_name, deer_columns: deer_columns}, cached_count: cached_count, records_per_table_limit: per_table_limit} = assigns) do
    ~L"""
    <div>
      <%= if @editing_table_id == nil do %>
        <strong>
          <%= live_redirect "#{table_name}", to: Routes.live_path(@socket, PjeskiWeb.DeerRecordsLive.Index, table_id) %>
        </strong>

        (<%= cached_count %>/<%= per_table_limit %>)

        <%= if cached_count == 0 do %>
          <a href="#" phx-click="delete_table" phx-value-table_id="<%= table_id %>"><%= gettext("Delete") %></a>
        <% end %>

        <a href="#" phx-click="toggle_table_edit" phx-value-table_id="<%= table_id %>"><%= gettext("Edit") %></a>
      <% else %>
        <strong><%= table_name %></strong>
        (<%= cached_count %>)
      <% end %>

      <br>

      <%= for %{name: name} <- deer_columns do %>
        <%= name %><br>
      <% end %>
    </div>
    """
  end
end
