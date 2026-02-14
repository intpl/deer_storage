defmodule DeerStorageWeb.DeerDashboardLive.DeerTableShowComponent do
  alias DeerStorageWeb.Router.Helpers, as: Routes
  use Phoenix.LiveComponent

  use Gettext, backend: DeerStorageWeb.Gettext
  import Phoenix.Component

  def render(assigns) do
    ~H"""
    <div>
      <%= if @editing_table_id == nil do %>
        <strong>
          <.link navigate={Routes.live_path(@socket, DeerStorageWeb.DeerRecordsLive.Index, @table.id)}>
            <%= @table.name %>
          </.link>
        </strong>

        (<%= @cached_count %>/<%= @records_per_table_limit %>)

      <% else %>
        <strong><%= @table.name %></strong>
        (<%= @cached_count %>)
      <% end %>

      <br>

      <%= for %{name: name} <- @table.deer_columns do %>
        <%= name %><br>
      <% end %>

      <br>

      <a href="#" phx-click="toggle_table_edit" phx-value-table_id={@table.id} class="button is-small"><%= gettext("Edit") %></a>
        <%= if @cached_count == 0 do %>
          <a href="#"
            phx-click="delete_table"
            phx-value-table_id={@table.id}
            class="button is-small is-warning">
              <%= gettext("Delete") %>
          </a>
        <% else %>
          <a href="#"
            phx-click="destroy_table_with_data"
            phx-value-table_id={@table.id}
            class="button is-small is-danger"
            data-confirm={gettext("Are you sure you want to delete this table, all of the records, shared links and uploaded files?")}>
              <%= gettext("Delete") %>
          </a>
        <% end %>
    </div>
    """
  end
end
