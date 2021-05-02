defmodule DeerStorageWeb.DeerRecordsLive.Modal.CreatedSharedRecordComponent do
  use Phoenix.LiveComponent
  import DeerStorageWeb.Gettext

  def render(assigns) do
    ~L"""
      <script>
        function copyGeneratedUrl() {
          const element = document.getElementById('created_shared_record_generated_url');
          element.select();
          document.execCommand("copy");
        }
      </script>

      <div class="modal is-active" id="created_shared_record">
        <div class="modal-background"></div>
        <div class="modal-card">
          <header class="modal-card-head">
            <p class="modal-card-title">
              <%= gettext("Share") %>
            </p>
            <a class="delete" aria-label="close" data-bulma-modal="close" href="#" phx-click="close_shared_link"></a>
          </header>

          <section class="modal-card-body">
            <div class"container" id="created_shared_record_generated_url">
              <%= @current_shared_link %>
            </div>
          </section>

          <footer class="modal-card-foot">
            <a id="copy_to_clipboard_and_close" class="button is-success" data-bulma-modal="close" href="#" phx-click="close_shared_link" phx-hook="hookCopyUrlToClipboard">
              <%= gettext("Copy to clipboard and close") %>
            </a>
            <a class="button" data-bulma-modal="close" href="#" phx-click="close_shared_link"><%= gettext("Close") %></a>
          </footer>

        </div>
      </div>
    """
  end
end
