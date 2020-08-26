defmodule PjeskiWeb.DeerRecordsLive.ShowComponent do
  use Phoenix.LiveComponent
  import PjeskiWeb.Gettext
  import Phoenix.Controller, only: [get_csrf_token: 0]

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
        </div>

        <form action="/upload" class="dropzone needsclick" id="dropzone-for-<%= record.id %>">
          <div class="dz-message needsclick">
            <button type="button" class="dz-button">Drop files here or click to upload.</button><br />
            <span class="note needsclick">(This is just a demo dropzone. Selected files are <strong>not</strong> actually uploaded.)</span>
          </div>
        </form>

        <script>
        $("#dropzone-for-<%= record.id %>").dropzone({
          url: "/upload",
          headers: {'_csrf_token': "<%= get_csrf_token() %>"},
        });
        </script>
      </div>
    </section>
    </div>
    """
  end
end
