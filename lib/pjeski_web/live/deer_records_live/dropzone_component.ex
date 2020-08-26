defmodule PjeskiWeb.DeerRecordsLive.DropzoneComponent do
  use Phoenix.LiveComponent
  import PjeskiWeb.Gettext

  def render(assigns) do
    ~L"""
    <div>
      <br />
      <form action="/upload" class="dropzone needsclick" id="dropzone-<%= @id %>" data-record-id="<%= @id %>" phx-hook="dropzoneHook">
        <div class="dz-message needsclick">
          <button type="button" class="dz-button">
            <%= gettext("Drop files here or click to upload.") %>
          </button>
        </div>
      </form>
    </div>
    """
  end
end
