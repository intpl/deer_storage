defmodule PjeskiWeb.DeerRecordsLive.Modal.PreviewFileComponent do
  alias PjeskiWeb.Router.Helpers, as: Routes
  use Phoenix.LiveComponent
  import PjeskiWeb.Gettext

  def render(%{deer_file: %{id: file_id}, record_id: record_id} = assigns) do
    ~L"""
      <div class="modal is-active">
        <a class="modal-background" phx-click="close_preview_modal" style="cursor: default;"></a>
        <div class="modal-content">
          <p class="image">
            <img src="<%= Routes.deer_files_path(@socket, :download_record, record_id, file_id) %>">
          </p>
        </div>
        <a class="modal-close is-large" data-bulma-modal="close" href="#" phx-click="close_preview_modal"><%= gettext("Close") %></a>
      </div>
    """
  end
end
