defmodule PjeskiWeb.DeerDashboardLive.DeerTableEditComponent do
  use Phoenix.LiveComponent

  alias Pjeski.Subscriptions.DeerTable

  import PjeskiWeb.Gettext
  import Phoenix.HTML.Form

  import PjeskiWeb.ErrorHelpers, only: [error_tag: 2]

  def render(%{table: %{id: id}, changeset: changeset} = assigns) do
    ~L"""
    <p>
      <a phx-click="cancel_edit"><%= gettext("Cancel") %></a>
      <%= form_for changeset, "#", [phx_change: :validate_edit, phx_submit: :save_edit], fn f -> %>
        <%= hidden_input f, :id, value: id %>

        <%= label f, gettext("Name"), class: 'label field-label' %>
        <%= text_input f, :name, class: 'input' %>
        <%= error_tag f, :name %>

        <br>

        <%= label f, gettext("Columns"), class: 'label field-label' %>

        <%= inputs_for f, :deer_columns, fn dc -> %>
          <div class="field-body">
            <div class="field">
              <%= text_input dc, :name, class: 'input' %>
              <%= error_tag dc, :name %>
            </div>
          </div>
        <% end %>

        <%= if @show_add_column do %>
          <a phx-click="add_column" phx-target="<%= @myself %>"><%= gettext("Add column") %></a>
          <br><br>
        <% end %>

        <%= submit gettext("Submit"), class: "button" %>
      <% end %>
    </p>
    """
  end

  def handle_event("add_column", %{}, socket) do
    changeset = socket.assigns.changeset
    deer_columns = changeset.data.deer_columns |> Enum.map(&Map.from_struct/1)

    new_changeset = DeerTable.changeset(changeset, %{deer_columns: deer_columns ++ [%{name: ""}]})

    {:noreply, socket |> assign(changeset: new_changeset, show_add_column: false)}
  end
end
