defmodule PjeskiWeb.DeerRecordsLive.ShowComponent do
  use Phoenix.LiveComponent
  import PjeskiWeb.Gettext

  import PjeskiWeb.DeerRecordView, only: [
    deer_columns_from_subscription: 2,
    deer_field_content_from_column_id: 2
  ]

  def render(%{record: record, subscription: subscription, table_id: table_id} = assigns) do
    deer_columns = deer_columns_from_subscription(subscription, table_id)

    ~L"""
    <section class="hero" id="<%= record.id %>">
      <div class="hero-body is-paddingless">
        <div class="container">
          <h3 class="subtitle">
            <a phx-click="edit" phx-value-record_id="<%= record.id %>">
              <%= gettext("Edit") %>
            </a>

            <a phx-click="delete" phx-value-record_id="<%= record.id %>" data-confirm="<%= gettext("Are you sure to REMOVE this record?") %>">
              <%= gettext("Delete") %>
            </a>
          </h3>
          <ul>
            <%= for %{id: column_id, name: column_name} <- deer_columns do %>
              <li>
                <strong><%= column_name %>:</strong>
                <%= deer_field_content_from_column_id(@record, column_id) %>
              </li>
            <% end %>
          </ul>
        </div>
      </div>
    </section>
    </div>
    """
  end
end
