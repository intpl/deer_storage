defmodule DeerStorageWeb.DeerRecordsLive.ShowComponent do
  use Phoenix.LiveComponent
  alias DeerStorageWeb.Router.Helpers, as: Routes
  import Phoenix.HTML.Link, only: [link: 2]
  import DeerStorageWeb.Gettext
  import DeerStorageWeb.DateHelpers, only: [dt: 2]

  import DeerStorageWeb.DeerRecordView,
    only: [
      deer_columns_from_subscription: 2,
      deer_table_from_subscription: 2,
      deer_field_content_from_column_id: 2,
      display_filesize_from_kilobytes: 1,
      mimetype_is_previewable?: 1,
      maybe_shrink_filename: 1
    ]

  def mount(socket), do: {:ok, assign(socket, :display_full_names, false)}

  def render(
        %{
          record: record,
          subscription: subscription,
          table_id: table_id,
          current_user: current_user
        } = assigns
      ) do
    deer_columns = deer_columns_from_subscription(subscription, table_id)

    ~L"""
    <div class="scrollable-vh75 overwrite-padding-top-120">
      <div class="field is-grouped">
        <a class="is-small button" href="#" phx-click="close_show" phx-value-id="<%= record.id %>">
          <span class="delete"></span>&nbsp;
        </a>

        <a class="is-small button" href="#" phx-click="edit" phx-value-record_id="<%= record.id %>">
          <%= gettext("Edit") %>
        </a>

        <div class="dropdown is-hoverable">
          <div class="dropdown-trigger">
            <a class="is-small button">
              <%= gettext("Sharing") %> ↷
            </a>
          </div>
          <div class="dropdown-menu">
            <div class="dropdown-content">
              <a href="#" class="dropdown-item" href="#" phx-click="share" phx-value-record_id="<%= record.id %>">
                <%= gettext("Share for 90 days") %>
              </a>
              <a href="#" class="dropdown-item" href="#" phx-click="share-for-editing" phx-value-record_id="<%= record.id %>">
                <%= gettext("Share to edit for 90 days") %>
              </a>
              <a href="#" class="dropdown-item" href="#" phx-click="invalidate-shared-links" phx-value-record_id="<%= record.id %>" data-confirm="<%= gettext("Are you sure you want to delete all shared links for this record and files in it?") %>">
                <%= gettext("Delete/invalidate all shared links") %>
              </a>
            </div>
          </div>
        </div>

        <a class="is-small button is-danger is-outlined" href="#" phx-click="delete" phx-value-record_id="<%= record.id %>" data-confirm="<%= gettext("Are you sure to REMOVE this record?") %>">
          <%= gettext("Delete") %>
        </a>
      </div>
      <ul>
        <%= Enum.map(deer_columns, fn %{id: column_id, name: column_name} -> %>
          <li>
            <strong><%= column_name %>:</strong>
            <%= deer_field_content_from_column_id(@record, column_id) %>
          </li>
        <% end) %>
        <br>
        <%= case [dt(current_user, record.inserted_at), dt(current_user, record.updated_at)] do %>
          <% [inserted_at, inserted_at] -> %>
              <li><%= gettext("Created at") %>: <b><%= inserted_at %></b></li>
          <% [inserted_at, updated_at] -> %>
            <li><%= gettext("Created at") %>: <b><%= inserted_at %></b></li>
            <li><%= gettext("Updated at") %>: <b><%= updated_at %></b></li>
        <% end %>
      </ul>

      <div class="prewrapped">
        <%= @record.notes %>
      </div>

      <a href="#" phx-click="toggle_fullnames" phx-target="<%= @myself %>">
        <%= if assigns.display_full_names do %>
          <%= gettext("Show short filenames") %>
        <% else %>
          <%= gettext("Show full filenames") %>
        <% end %>
      </a>

      <br>
      <br>

      <ul>
        <%= Enum.map(record.deer_files, fn %{id: file_id, original_filename: name, kilobytes: kilobytes, mimetype: mimetype} -> %>
          <% download_url = Routes.deer_files_path(@socket, :download_record, @record.id, file_id) %>
          <li>
            <%= if mimetype_is_previewable?(mimetype) do %>
              <a href="#" phx-click="preview_record_file" phx-value-record-id="<%= record.id %>" phx-value-file-id="<%= file_id %>" title="<%= name %>"> <%= maybe_shrink_if_not_fullnames(assigns, name) %> </a>
            <% else %>
              <%= link maybe_shrink_if_not_fullnames(assigns, name), to: download_url, title: name %>
            <% end %>
            (<%= display_filesize_from_kilobytes(kilobytes) %>)

          <div class="dropdown is-hoverable is-right">
            <div class="dropdown-trigger">
              <span class="button is-small">↴</span>
            </div>
            <div class="dropdown-menu">
              <div class="dropdown-content">
                <a class="dropdown-item" href="<%= download_url %>">
                  <span><%= gettext("Download") %></span>
                </a>
                <a class="dropdown-item" href="#" phx-click="share_record_file" phx-value-record-id="<%= record.id %>" phx-value-file-id="<%= file_id %>">
                  <span><%= gettext("Share") %></span>
                </a>
                <a class="dropdown-item" href="#" phx-click="delete_record_file" phx-value-record-id="<%= record.id %>" phx-value-file-id="<%= file_id %>" data-confirm="<%= gettext("Are you sure to DELETE this file?") %>">
                  <span class="delete"></span>&nbsp;
                  <span><%= gettext("Delete") %></span>
                </a>
              </div>
            </div>
          </li>
        <% end) %>
      </ul>

      <br>

      <a class="is-small button is-link is-light" href="#" phx-click="new_connected_record" phx-value-connecting-with-record_id="<%= record.id %>">
        <span><%= gettext("Create connected record") %></span>
      </a>

      <a class="is-small button is-link is-light" href="#" phx-click="show_connect_record_modal" phx-value-record_id="<%= record.id %>">
        <span><%= gettext("Connect") %></span>
      </a>

      <a class="is-small button is-link" href="#" phx-click="show_upload_file_modal" phx-value-record_id="<%= record.id %>" phx-value-table_id="<%= record.deer_table_id %>">
        <span><%= gettext("Upload file(s)") %></span>
      </a>

      <br>
      <br>

      <ul>
        <%= Enum.map(@connected_records, fn connected_record -> %>
          <% %{name: table_name, deer_columns: connected_record_deer_columns} = deer_table_from_subscription(subscription, connected_record.deer_table_id) %>
          <article class="message">
            <div class="message-header">
              <p><%= table_name %></p>

              <div>
                <a href="#"
                        phx-click="redirect_to_connected_record"
                        phx-value-record_id="<%= connected_record.id %>"
                        phx-value-table_id="<%= connected_record.deer_table_id %>"
                        class="is-small button is-success is-light">
                  <%= gettext("Open") %>
                </a>

                <a href="#" class="is-small button is-info" phx-click="show_upload_file_modal" phx-value-record_id="<%= connected_record.id %>" phx-value-table_id="<%= connected_record.deer_table_id %>">
                  <span><%= gettext("Upload file(s)") %></span>
                </a>

                <a href="#" class="is-small button is-danger is-light" phx-click="disconnect_records" phx-value-opened_record_id="<%= record.id %>" phx-value-connected_record_id="<%= connected_record.id %>" data-confirm="<%= gettext("Are you sure you want to unlink these records from each other?") %>">
                  <%= gettext("Disconnect") %>
                </a>
              </div>
            </div>
            <div class="message-body">
              <%= Enum.map(connected_record_deer_columns, fn %{id: column_id, name: column_name} -> %>
                <strong><%= column_name %>:</strong>
                <%= deer_field_content_from_column_id(connected_record, column_id) %><br />
              <% end) %>

              <br>

              <%= case [dt(current_user, connected_record.inserted_at), dt(current_user, connected_record.updated_at)] do %>
              <% [inserted_at, inserted_at] -> %> <li><%= gettext("Created at") %>: <b><%= inserted_at %></b></li>
              <% [inserted_at, updated_at] -> %>
                <li><%= gettext("Created at") %>: <b><%= inserted_at %></b></li>
                <li><%= gettext("Updated at") %>: <b><%= updated_at %></b></li>
              <% end %>

              <div class="prewrapped">
                <%= connected_record.notes %>
              </div>

              <%= if Enum.any?(connected_record.deer_files) do %>
                <br />

                <%= Enum.map(connected_record.deer_files, fn %{id: file_id, original_filename: name, kilobytes: kilobytes, mimetype: mimetype} -> %>
                  <p>
                    <%= if mimetype_is_previewable?(mimetype) do %>
                      <a href="#" phx-click="preview_record_file" phx-value-record-id="<%= connected_record.id %>" phx-value-file-id="<%= file_id %>" title="<%= name %>"> <%= maybe_shrink_if_not_fullnames(assigns, name) %> </a>
                    <% else %>
                      <%= link maybe_shrink_if_not_fullnames(assigns, name), to: Routes.deer_files_path(@socket, :download_record, connected_record.id, file_id), title: name %>
                    <% end %>
                    (<%= display_filesize_from_kilobytes(kilobytes) %>)
                  </p>
                <% end) %>
              <% end %>
            </div>
          </article>
        <% end) %>
      </ul>
    </div>
    """
  end

  def handle_event(
        "toggle_fullnames",
        _,
        %{assigns: %{display_full_names: previous_display_value}} = socket
      ) do
    {:noreply, assign(socket, :display_full_names, !previous_display_value)}
  end

  defp maybe_shrink_if_not_fullnames(%{display_full_names: true}, filename), do: filename
  defp maybe_shrink_if_not_fullnames(_, filename), do: maybe_shrink_filename(filename)
end
