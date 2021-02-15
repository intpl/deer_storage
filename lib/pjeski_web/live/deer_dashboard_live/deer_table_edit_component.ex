defmodule PjeskiWeb.DeerDashboardLive.DeerTableEditComponent do
  use Phoenix.LiveComponent

  import PjeskiWeb.Gettext
  import Phoenix.HTML.Form

  import PjeskiWeb.ErrorHelpers, only: [error_tag: 2]

  def update(%{changeset: changeset, table: %{id: table_id}, columns_per_table_limit: columns_per_table_limit}, socket) do
    {:ok, assign(
        socket,
        table_id: table_id,
        changeset: changeset,
        columns_per_table_limit: columns_per_table_limit,
        columns_count: length(Ecto.Changeset.fetch_field!(changeset, :deer_columns)))}
  end

  def render(assigns) do
    ~L"""
    <div>
      <%= form_for @changeset, "#", [phx_change: :validate_table_edit, phx_submit: :save_table_edit, autocomplete: "off"], fn f -> %>
        <%= hidden_input f, :id, value: @table_id %>

        <%= label f, gettext("Name"), class: 'label field-label' %>
        <%= text_input f, :name, class: 'input' %>
        <%= error_tag f, :name %>

        <br>

        <%= label f, gettext("Columns"), class: 'label field-label' %>

        <%= inputs_for f, :deer_columns, fn dc -> %>
          <div class="field is-grouped">
            <p class="control">
              <a class="button is-small" href="#" phx-click="move_column_up" phx-value-index="<%= dc.index %>">▲</a>
              <a class="button is-small" href="#" phx-click="move_column_down" phx-value-index="<%= dc.index %>">▼</a>
            </p>
            <p class="control">
              <div class="field">
                <%= text_input dc, :name, class: 'input is-small' %>
                <%= error_tag dc, :name %>
              </div>
            </p>
          </div>
        <% end %>

        <%= if @columns_count < @columns_per_table_limit do %>
          <a href="#" phx-click="add_column"><%= gettext("Add column") %></a>
          (<%= @columns_count %>/<%= @columns_per_table_limit %>)
        <% else %>
          <i><%= gettext("You can't add more columns") %></i>
        <% end %>

        <br><br>

        <%= submit gettext("Save"), class: "button is-success" %>
        <a href="#" phx-click="cancel_table_edit" class="button"><%= gettext("Cancel") %></a>
      <%  end %>
    </div>
    """
  end

end
