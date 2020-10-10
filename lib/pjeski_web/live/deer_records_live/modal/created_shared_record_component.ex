defmodule PjeskiWeb.DeerRecordsLive.Modal.CreatedSharedRecordComponent do
  use Phoenix.LiveComponent
  alias PjeskiWeb.Router.Helpers, as: Routes

  import PjeskiWeb.Gettext

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
              <%= gettext("Share record") %>
            </p>
            <a class="delete" aria-label="close" data-bulma-modal="close" href="#" phx-click="close_shared_record"></a>
          </header>

          <section class="modal-card-body">
            <div class"container" id="created_shared_record_generated_url">
              <%= Routes.live_url(
                PjeskiWeb.Endpoint,
                PjeskiWeb.SharedRecordsLive.Show,
                @subscription_id,
                @current_shared_record_uuid
              ) %>
            </div>
          </section>

          <footer class="modal-card-foot">
            <a id="copy_to_clipboard_and_close" class="button is-success" data-bulma-modal="close" href="#" phx-click="close_shared_record" phx-hook="hookCopyUrlToClipboard">
              <%= gettext("Copy to clipboard and close") %>
            </a>
            <a class="button" data-bulma-modal="close" href="#" phx-click="close_shared_record"><%= gettext("Close") %></a>
          </footer>

        </div>
      </div>
    """
  end
end
