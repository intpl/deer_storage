defmodule PjeskiWeb.DeerRecordsLive.Modal.NewComponent do
  use Phoenix.LiveComponent
  import PjeskiWeb.Gettext
  import Phoenix.HTML.Form
  import PjeskiWeb.DeerRecordView, only: [
    deer_column_name_from_id: 2,
    deer_columns_from_subscription: 2
  ]

  def render(%{changeset: changeset, subscription: subscription, table_id: table_id, table_name: table_name} = assigns) do
    deer_columns = deer_columns_from_subscription(subscription, table_id)

    ~L"""
      <div class="modal is-active" id="new_record">
        <div class="modal-background"></div>
        <div class="modal-card">
          <header class="modal-card-head">
            <p class="modal-card-title">
              <%= gettext("Insert record to table") %>: <%= table_name %>
            </p>
            <button class="delete" aria-label="close" data-bulma-modal="close" phx-click="close_new"></button>
          </header>
          <%= form_for changeset, "#", [phx_change: :validate_new, phx_submit: :save_new], fn f -> %>
            <section class="modal-card-body">
              <div class"container">
                <%= inputs_for f, :deer_fields, fn df -> %>
                  <div class="field is-horizontal">
                    <%= label df, deer_column_name_from_id(deer_columns, df.params["deer_column_id"]), class: 'label field-label' %>

                    <div class="field-body">
                      <div class="field">
                        <%= hidden_input df, :deer_column_id %>
                        <%= text_input df, :content, class: 'input' %>
                        <%#= error_tag df, :content %>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
            </section>

            <footer class="modal-card-foot">
              <%= submit gettext("Create record"), class: "button is-success", onclick: "window.scrollTo(0,0)" %>
              <a class="button" data-bulma-modal="close" phx-click="close_new"><%= gettext("Cancel") %></a>
            </footer>
          <% end %>
        </div>
      </div>
    """
  end
end
