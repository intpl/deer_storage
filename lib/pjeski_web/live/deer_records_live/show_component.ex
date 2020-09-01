defmodule PjeskiWeb.DeerRecordsLive.ShowComponent do
  use Phoenix.LiveComponent
  alias PjeskiWeb.Router.Helpers, as: Routes
  import Phoenix.HTML.Link, only: [link: 2]
  import PjeskiWeb.Gettext

  import PjeskiWeb.DeerRecordView, only: [
    deer_columns_from_subscription: 2,
    deer_field_content_from_column_id: 2
  ]

  def render(%{record: record, subscription: subscription, table_id: table_id} = assigns) do
    deer_columns = deer_columns_from_subscription(subscription, table_id)

    ~L"""
    <div class="hero-body is-paddingless">
      <div class="container">
        <h3 class="subtitle">
          <button class="button" phx-click="close_show" phx-value-id="<%= record.id %>">
            <span class="delete"></span>&nbsp;
            <span><%= gettext("Close") %></span>
          </button>

          <button class="button" phx-click="edit" phx-value-record_id="<%= record.id %>">
            <%= gettext("Edit") %>
          </button>

          <button class="button is-danger is-outlined" phx-click="delete" phx-value-record_id="<%= record.id %>" data-confirm="<%= gettext("Are you sure to REMOVE this record?") %>">
            <%= gettext("Delete") %>
          </button>
        </h3>
        <ul>
          <%= Enum.map(deer_columns, fn %{id: column_id, name: column_name} -> %>
            <li>
              <strong><%= column_name %>:</strong>
              <%= deer_field_content_from_column_id(@record, column_id) %>
            </li>
          <% end) %>
        </ul>

        <hr>

        <ul>
          <%= Enum.map(record.deer_files, fn %{id: file_id, original_filename: name} -> %>
            <li>
              <span>
                <%= link name, to: Routes.deer_files_path(@socket, :download_record, @record.id, file_id) %>
              </span>
            </li>
          <% end) %>
        </ul>
      </div>
    </div>
    """
  end
end
