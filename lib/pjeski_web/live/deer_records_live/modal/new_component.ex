defmodule PjeskiWeb.DeerRecordsLive.Modal.NewComponent do
  use Phoenix.LiveComponent
  import PjeskiWeb.Gettext
  import Phoenix.HTML.Form
  import PjeskiWeb.DeerRecordView, only: [deer_columns_from_subscription: 2, render_prepared_fields: 1, prepare_fields_for_form: 2]

  def update(%{changeset: changeset, subscription: subscription, table_id: table_id, table_name: table_name, cached_count: cached_count, connecting_record?: can_change_table_id?}, socket) do
    deer_columns = deer_columns_from_subscription(subscription, table_id)

    {:ok, assign(socket,
      changeset: changeset,
      callbacks: get_callback_names(can_change_table_id?),
      deer_columns: deer_columns,
      can_change_table_id?: can_change_table_id?,
      deer_tables: if(can_change_table_id?, do: Enum.map(subscription.deer_tables, fn dt -> {dt.id, dt.name} end), else: []),
      prepared_fields: prepare_fields_for_form(deer_columns, changeset),
      can_create_records?: cached_count < subscription.deer_records_per_table_limit,
      table_name: table_name,
      table_id: table_id
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
            <a class="delete" aria-label="close" data-bulma-modal="close" href="#" phx-click="<%= @callbacks[:close] %>"></a>
          </header>
          <section class="modal-card-body">
            <%= if @can_change_table_id? do %>
              <div class="control">
                <div class="select">
                  <form phx-change="change_new_connected_record_table_id">
                    <select name="table_id">
                      <%= for {id, name} <- @deer_tables do %>
                        <option value="<%= id %>" <%= if id == @table_id, do: "selected" %>><%= name %></option>
                      <% end %>
                    </select>
                  </form>
                </div>
              </div>
            <% end %>

          </section>
          <%= form_for @changeset, "#", [phx_change: @callbacks[:change], phx_submit: @callbacks[:submit]], fn _ -> %>
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

              <a class="button" data-bulma-modal="close" href="#" phx-click="<%= @callbacks[:close] %>"><%= gettext("Cancel") %></a>
            </footer>
          <% end %>
        </div>
      </div>
    """
  end

  def get_callback_names(false), do: [close: :close_new, change: :validate_new, submit: :save_new]
  def get_callback_names(true), do: [close: :close_new_connected_record, change: :validate_new_connected_record, submit: :save_new_connected_record]
end
