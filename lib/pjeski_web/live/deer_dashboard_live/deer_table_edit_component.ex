defmodule PjeskiWeb.DeerDashboardLive.DeerTableEditComponent do
  use Phoenix.LiveComponent

  import PjeskiWeb.Gettext
  import Phoenix.HTML.Form

  import PjeskiWeb.ErrorHelpers, only: [error_tag: 2]

  def render(%{table: %{id: id}, changeset: changeset} = assigns) do
    columns_count = length(Ecto.Changeset.fetch_field!(changeset, :deer_columns))

    ~L"""
    <div>
      <a href="#" phx-click="cancel_table_edit"><%= gettext("Cancel") %></a>
      <%= form_for changeset, "#", [phx_change: :validate_table_edit, phx_submit: :save_table_edit], fn f -> %>
        <%= hidden_input f, :id, value: id %>

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

        <%= if columns_count < @columns_per_table_limit do %>
          <a href="#" phx-click="add_column"><%= gettext("Add column") %></a>
          (<%= columns_count %>/<%= @columns_per_table_limit %>)
        <% else %>
          <i><%= gettext("You can't add more columns") %></i>
        <% end %>

        <br><br>

        <%= submit gettext("Save"), class: "button" %>
      <%  end %>
    </div>
    """
  end

end
