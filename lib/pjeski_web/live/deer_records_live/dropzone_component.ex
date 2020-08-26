defmodule PjeskiWeb.DeerRecordsLive.DropzoneComponent do
  use Phoenix.LiveComponent
  import PjeskiWeb.Gettext
  import Phoenix.Controller, only: [get_csrf_token: 0]

  import PjeskiWeb.DeerRecordView, only: [
    deer_columns_from_subscription: 2,
    deer_field_content_from_column_id: 2
  ]

  def render(assigns) do
    ~L"""
    <div>
      <br />
      <form action="/upload" class="dropzone needsclick" id="dropzone-for-<%= @id %>">
        <div class="dz-message needsclick">
          <button type="button" class="dz-button">
            <%= gettext("Drop files here or click to upload.") %>
          </button>
        </div>
      </form>

      <script>
      $("#dropzone-for-<%= @id %>").dropzone({
        url: "/upload",
        headers: {'_csrf_token': "<%= get_csrf_token() %>"},
      });
      </script>
    </div>
    """
  end
end
