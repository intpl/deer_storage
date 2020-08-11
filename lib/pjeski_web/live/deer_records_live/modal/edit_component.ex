# FIXME REFACTOR THIS BECAUSE IT'S THE SAME AS NEW COMPONENT
defmodule PjeskiWeb.DeerRecordsLive.Modal.EditComponent do
  use Phoenix.LiveComponent
  import PjeskiWeb.Gettext
  import Phoenix.HTML.Form
  import PjeskiWeb.DeerRecordView, only: [deer_columns_from_subscription: 2]

  def update(%{changeset: changeset, subscription: subscription, table_id: table_id, table_name: table_name}, socket) do
    deer_columns = deer_columns_from_subscription(subscription, table_id)
    deer_fields = Ecto.Changeset.fetch_field!(changeset, :deer_fields)

    prepare_field = fn {dc, index} -> %{
          id: dc.id,
          index: index,
          name: dc.name,
          value: Enum.find_value(deer_fields, fn df -> df.deer_column_id == dc.id && df.content end)
      }
    end

    {:ok, assign(socket,
      changeset: changeset,
      deer_columns: deer_columns,
      prepared_fields: deer_columns |> Enum.with_index |> Enum.map(prepare_field),
      table_name: table_name
    )}
  end

  def render(assigns) do
    ~L"""
      <div class="modal is-active" id="editing_record">
        <div class="modal-background"></div>
        <div class="modal-card">
          <header class="modal-card-head">
            <p class="modal-card-title">
              <%= gettext("Edit record from table") %>: <%= @table_name %>
            </p>
            <button class="delete" aria-label="close" data-bulma-modal="close" phx-click="close_edit"></button>
          </header>
          <%= form_for @changeset, "#", [phx_change: :validate_edit, phx_submit: :save_edit], fn _ -> %>
            <section class="modal-card-body">
              <div class"container">
                <%= for %{id: column_id, name: column_name, index: index, value: value} <- @prepared_fields do %>
                  <div class="field is-horizontal">
                    <label class="label field-label"><%= column_name %></label>

                    <div class="field-body">
                      <div class="field">
                        <input id="deer_record_deer_fields_<%= index %>_deer_column_id" name="deer_record[deer_fields][<%= index %>][deer_column_id]" type="hidden" value="<%= column_id %>">
                        <input class="input" id="deer_record_deer_fields_<%= index %>_content" name="deer_record[deer_fields][<%= index %>][content]" type="text" value="<%= value %>">
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
            </section>

            <footer class="modal-card-foot">
              <%= if @changeset.valid? do %>
                <%= submit gettext("Save changes"), class: "button is-success" %>
              <% end %>

              <a class="button" data-bulma-modal="close" phx-click="close_edit"><%= gettext("Cancel") %></a>
            </footer>
          <% end %>
        </div>
      </div>
    """
  end
end
