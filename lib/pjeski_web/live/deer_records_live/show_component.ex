defmodule PjeskiWeb.DeerRecordsLive.ShowComponent do
  use Phoenix.LiveComponent
  alias PjeskiWeb.Router.Helpers, as: Routes
  import Phoenix.HTML.Link, only: [link: 2]
  import PjeskiWeb.Gettext

  import PjeskiWeb.DeerRecordView, only: [
    deer_columns_from_subscription: 2,
    deer_table_from_subscription: 2,
    deer_field_content_from_column_id: 2,
    display_filesize_from_kilobytes: 1
  ]

  def render(%{record: record, subscription: subscription, table_id: table_id} = assigns) do
    deer_columns = deer_columns_from_subscription(subscription, table_id)

    ~L"""
    <div class="hero-body is-paddingless">
      <div class="container">
        <h3 class="subtitle">
          <a class="button" href="#" phx-click="close_show" phx-value-id="<%= record.id %>">
            <span class="delete"></span>&nbsp;
            <span><%= gettext("Close") %></span>
          </a>

          <a class="button" href="#" phx-click="edit" phx-value-record_id="<%= record.id %>">
            <%= gettext("Edit") %>
          </a>

          <a class="button is-success" href="#" phx-click="share" phx-value-record_id="<%= record.id %>">
            <%= gettext("Share") %>
          </a>

          <a class="button is-danger is-outlined" href="#" phx-click="delete" phx-value-record_id="<%= record.id %>" data-confirm="<%= gettext("Are you sure to REMOVE this record?") %>">
            <%= gettext("Delete") %>
          </a>
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
          <%= Enum.map(record.deer_files, fn %{id: file_id, original_filename: name, kilobytes: kilobytes} -> %>
            <li>
              <p>
                <%= link name, to: Routes.deer_files_path(@socket, :download_record, @record.id, file_id) %>
                (<%= display_filesize_from_kilobytes(kilobytes) %>)

                <a class="button" href="#" phx-click="delete_record_file" phx-value-record-id="<%= record.id %>" phx-value-file-id="<%= file_id %>" data-confirm="<%= gettext("Are you sure to DELETE this file?") %>">
                  <span class="delete"></span>&nbsp;
                  <span><%= gettext("Delete") %></span>
                </a>
              </p>
            </li>
          <% end) %>
        </ul>

        <ul>
          <%= Enum.map(@connected_records, fn connected_record -> %>
            <% %{name: table_name, deer_columns: connected_record_deer_columns} = deer_table_from_subscription(subscription, connected_record.deer_table_id) %>
            <article class="message">
              <div class="message-header">
                <p><%= table_name %></p>
                <a class="button is-danger is-outlined is-light" href="#" phx-click="disconnect_records" phx-value-opened_record_id="<%= record.id %>" phx-value-connected_record_id="<%= connected_record.id %>" data-confirm="<%= gettext("Are you sure you want to unlink these records from each other?") %>">
                  <%= gettext("Disconnect") %>
                </a>
              </div>
              <div class="message-body">
                <%= Enum.map(connected_record_deer_columns, fn %{id: column_id, name: column_name} -> %>
                  <li>
                    <strong><%= column_name %>:</strong>
                    <%= deer_field_content_from_column_id(connected_record, column_id) %>
                  </li>
                <% end) %>
              </div>
            </article>
          <% end) %>
        </ul>

        <a class="button is-success" href="#" phx-click="show_connect_record_modal" phx-value-record_id="<%= record.id %>">
          <span><%= gettext("Connect a record") %></span>
        </a>
      </div>
    </div>
    """
  end
end
