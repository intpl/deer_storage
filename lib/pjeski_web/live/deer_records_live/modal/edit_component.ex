# FIXME REFACTOR THIS BECAUSE IT'S THE SAME AS NEW COMPONENT
defmodule PjeskiWeb.DeerRecordsLive.Modal.EditComponent do
  use Phoenix.LiveComponent
  import PjeskiWeb.Gettext
  import Phoenix.HTML.Form
  import PjeskiWeb.DeerRecordView, only: [deer_columns_from_subscription: 2, deer_field_content_from_column_id: 2]

  def update(%{changeset: changeset} = assigns, socket) do
    deer_columns = deer_columns_from_subscription(assigns.subscription, assigns.table_id)
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
      can_create_records: assigns.can_create_records,
      deer_columns: deer_columns,
      prepared_fields: deer_columns |> Enum.with_index |> Enum.map(prepare_field),
      table_name: assigns.table_name,
      editing_record_has_been_removed: assigns.editing_record_has_been_removed,
      old_editing_record: assigns.old_editing_record
    )}
  end

  def render(assigns) do
    ~L"""
      <div class="modal is-active" id="editing_record">
        <div class="modal-background"></div>
        <div class="modal-card">
          <header class="modal-card-head">
            <p class="modal-card-title">
              <%= if @table_name do %>
                <%= gettext("Edit record from table") %>: <%= @table_name %>
              <% else %>
                <%= gettext("Edit record") %>
              <% end %>
            </p>
            <a class="delete" aria-label="close" data-bulma-modal="close" href="#" phx-click="close_edit"></a>
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

              <%= cond do %>
                <% @old_editing_record -> %>
                  <div class="modal-card-body">
                    <p class="has-text-weight-semibold has-text-danger">
                      <%= gettext("This record has been updated while you were editing it.") %><br /><br />
                    </p>

                    <p class="has-text-danger">
                      <%= if @can_create_records do %>
                        <%= gettext("You can overwrite the following changes or copy your changes to an entirely new record.") %><br />
                      <% else %>
                        <%= gettext("You can overwrite the following changes.") %><br />
                      <% end %>
                    </p>

                    <br />

                    <ul>
                      <% changeset_deer_fields = Ecto.Changeset.fetch_field!(@changeset, :deer_fields) %>
                      <% old_deer_fields = Ecto.Changeset.fetch_field!(@old_editing_record, :deer_fields) %>
                      <%= Enum.map(@deer_columns, fn %{id: column_id, name: column_name} -> %>
                        <li>
                          <strong><%= column_name %>:</strong>
                          <% old_content = deer_field_content_from_column_id(old_deer_fields, column_id) %>
                          <% changeset_content = deer_field_content_from_column_id(changeset_deer_fields, column_id) %>

                          <%= if old_content == changeset_content do %>
                            <%= old_content %>
                          <% else %>
                            <span class="has-text-weight-semibold has-text-danger">
                              <%= old_content %>
                            </span>
                          <% end %>
                        </li>
                      <% end) %>
                    </ul>
                  </div>

                  <footer class="modal-card-foot">
                    <%= submit gettext("Overwrite displayed changes"), class: "button is-danger" %>
                    <br />

                    <%= if @can_create_records do %>
                      <a href="#" phx-click="move_editing_record_data_to_new_record" class="button button is-success"><%= gettext("Open form to create new record with this data") %></a>
                    <% end %>

                    <br />
                    <a href="#" phx-click="close_edit" class="button" data-bulma-modal="close"><%= gettext("Cancel") %></a>
                  </footer>

                <% @editing_record_has_been_removed -> %>
                  <div class="modal-card-body">
                    <p class="has-text-weight-semibold has-text-danger">
                      <%= gettext("This record has been removed while you were editing it.") %><br /><br />
                    </p>

                    <p class="has-text-danger">
                      <%= gettext("All uploaded files for this record are removed and record connections are lost.") %><br />
                      <%= gettext("You can still save this form data, but it will appear as a new record.") %><br />
                    </p>
                  </div>

                  <footer class="modal-card-foot">
                    <a href="#" phx-click="move_editing_record_data_to_new_record" class="button button is-warning"><%= gettext("Open form to create new record with this data") %></a>
                    <a href="#" phx-click="close_edit" class="button" data-bulma-modal="close"><%= gettext("Cancel") %></a>
                  </footer>

                <% true -> %>
                  <footer class="modal-card-foot">
                    <%= submit gettext("Save changes"), class: "button is-success" %>
                    <a href="#" class="button" data-bulma-modal="close" href="#" phx-click="close_edit"><%= gettext("Cancel") %></a>
                  </footer>
              <% end %>
          <% end %>
        </div>
      </div>
    """
  end
end
