defmodule PjeskiWeb.DeerRecordsLive.Modal.NewComponent do
  use Phoenix.LiveComponent
  import PjeskiWeb.Gettext
  import Phoenix.HTML.Form
  import PjeskiWeb.DeerRecordView, only: [deer_columns_from_subscription: 2, render_prepared_fields: 1, prepare_fields_for_form: 2]

  def update(%{changeset: changeset, subscription: subscription, table_id: table_id, table_name: table_name, cached_count: cached_count}, socket) do
    deer_columns = deer_columns_from_subscription(subscription, table_id)

    {:ok, assign(socket,
      changeset: changeset,
      deer_columns: deer_columns,
      prepared_fields: prepare_fields_for_form(deer_columns, changeset),
      can_create_records?: cached_count < subscription.deer_records_per_table_limit,
      table_name: table_name
    )}
  end

  def render(assigns) do
    ~L"""
      <div class="modal is-active" id="new_record">
        <div class="modal-background"></div>
        <div class="modal-card">
          <header class="modal-card-head">
            <p class="modal-card-title">
              <%= gettext("Insert record to table") %>: <%= @table_name %>
            </p>
            <a class="delete" aria-label="close" data-bulma-modal="close" href="#" phx-click="close_new"></a>
          </header>
          <%= form_for @changeset, "#", [phx_change: :validate_new, phx_submit: :save_new], fn _ -> %>
            <section class="modal-card-body">
              <div class"container">
                <%= render_prepared_fields(@prepared_fields) %>
              </div>
            </section>

            <footer class="modal-card-foot">
              <%= if @can_create_records? do %>
                <%= submit gettext("Create record"), class: "button is-success" %>
              <% else %>
                <p><%= gettext("You cannot create this record") %></p>&nbsp;
              <% end %>

              <a class="button" data-bulma-modal="close" href="#" phx-click="close_new"><%= gettext("Cancel") %></a>
            </footer>
          <% end %>
        </div>
      </div>
    """
  end
end
