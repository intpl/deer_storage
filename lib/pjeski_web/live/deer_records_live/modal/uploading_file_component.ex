defmodule PjeskiWeb.DeerRecordsLive.Modal.UploadingFileComponent do
  use Phoenix.LiveComponent
  import PjeskiWeb.Gettext

  def render(%{record_id: record_id} = assigns) do
    ~L"""
      <div class="modal is-active">
        <div class="modal-background"></div>
        <div class="modal-card">
          <header class="modal-card-head">
            <p class="modal-card-title">
              <%= gettext("Upload file(s)") %>
            </p>
            <a class="delete" aria-label="close" data-bulma-modal="close" href="#" phx-click="close_upload_file_modal"></a>
          </header>

          <section class="modal-card-body">
          Uploading file for record id <%= record_id %>
          </section>

          <footer class="modal-card-foot">
            <a class="button" data-bulma-modal="close" href="#" phx-click="close_upload_file_modal"><%= gettext("Close") %></a>
          </footer>
        </div>
      </div>
    """
  end
end
