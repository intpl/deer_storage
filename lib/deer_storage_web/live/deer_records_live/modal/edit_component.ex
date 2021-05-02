defmodule DeerStorageWeb.DeerRecordsLive.Modal.EditComponent do
  use Phoenix.LiveComponent
  import DeerStorageWeb.Gettext
  import Phoenix.HTML.Form
  import DeerStorageWeb.DeerRecordView, only: [
    deer_columns_from_subscription: 2,
    deer_field_content_from_column_id: 2,
    render_prepared_fields: 1,
    prepare_fields_for_form: 2
  ]

  def update(%{changeset: changeset} = assigns, socket) do
    deer_columns = deer_columns_from_subscription(assigns.subscription, assigns.table_id)

    {:ok, assign(socket,
      changeset: changeset,
      can_create_records: assigns.can_create_records,
      deer_columns: deer_columns,
      prepared_fields: prepare_fields_for_form(deer_columns, changeset),
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
          <%= form_for @changeset, "#", [phx_change: :validate_edit, phx_submit: :save_edit, autocomplete: "off"], fn f -> %>
            <section class="modal-card-body">
              <div class"container">
                <%= render_prepared_fields(@prepared_fields) %>
              </div>
              <hr>
              <div class="control">
                <%= textarea(f, :notes, class: "textarea", placeholder: gettext("Notes...")) %>
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
                      <% old_deer_fields = Ecto.Changeset.fetch_field!(@old_editing_record, :deer_fields) %>
                      <% old_notes = Ecto.Changeset.fetch_field!(@old_editing_record, :notes) %>
                      <% new_notes = Ecto.Changeset.fetch_field!(@changeset, :notes) %>
                      <% different_deer_fields = DeerStorageWeb.DeerRecordView.different_deer_fields(Ecto.Changeset.fetch_field!(@changeset, :deer_fields), old_deer_fields) %>

                      <%= if Enum.any?(different_deer_fields) do %>
                        <%= Enum.map(@deer_columns, fn %{id: column_id, name: column_name} -> %>
                          <li>
                            <strong><%= column_name %>:</strong>
                            <%= if Enum.member?(different_deer_fields, column_id) do %>
                              <span class="has-text-weight-semibold has-text-danger">
                                <%= deer_field_content_from_column_id(old_deer_fields, column_id) %>
                              </span>
                            <% else %>
                              <%= deer_field_content_from_column_id(old_deer_fields, column_id) %>
                            <% end %>
                          </li>
                        <%  end) %>
                      <% end %>

                      <%= if old_notes != new_notes do %>
                        <span class="has-text-danger">
                          <%= old_notes %>
                        </span>
                      <% end %>
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
