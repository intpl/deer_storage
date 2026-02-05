defmodule DeerStorageWeb.DeerDashboardLive.DeerTableShowComponent do
  alias DeerStorageWeb.Router.Helpers, as: Routes
  use Phoenix.LiveComponent

  import DeerStorageWeb.Gettext

  def render(
        %{
          table: %{id: table_id, name: table_name, deer_columns: deer_columns},
          cached_count: cached_count,
          records_per_table_limit: per_table_limit
        } = assigns
      ) do
    ~L"""
    <div>
      <%= if @editing_table_id == nil do %>
        <strong>
          <%= live_redirect "#{table_name}", to: Routes.live_path(@socket, DeerStorageWeb.DeerRecordsLive.Index, table_id) %>
        </strong>

        (<%= cached_count %>/<%= per_table_limit %>)

      <% else %>
        <strong><%= table_name %></strong>
        (<%= cached_count %>)
      <% end %>

      <br>

      <%= for %{name: name} <- deer_columns do %>
        <%= name %><br>
      <% end %>

      <br>

      <a href="#" phx-click="toggle_table_edit" phx-value-table_id="<%= table_id %>" class="button is-small"><%= gettext("Edit") %></a>
        <%= if cached_count == 0 do %>
          <a href="#"
            phx-click="delete_table"
            phx-value-table_id="<%= table_id %>"
            class="button is-small is-warning">
              <%= gettext("Delete") %>
          </a>
        <% else %>
          <a href="#"
            phx-click="destroy_table_with_data"
            phx-value-table_id="<%= table_id %>"
            class="button is-small is-danger"
            data-confirm="<%= gettext("Are you sure you want to delete this table, all of the records, shared links and uploaded files?") %>">
              <%= gettext("Delete") %>
          </a>
        <% end %>
    </div>
    """
  end
end
