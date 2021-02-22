defmodule PjeskiWeb.DeerRecordsLive.Modal.PreviewFileComponent do
  use Phoenix.LiveComponent
  import PjeskiWeb.Gettext

  def render(%{deer_file: %{original_filename: original_filename}} = assigns) do
    ~L"""
      <div class="modal is-active" phx-drop-target="<%= assigns[:drop_target_ref] %>">
        <div class="modal-background"></div>
        <div class="modal-card">
          <header class="modal-card-head">
            <p class="modal-card-title">
              <%= original_filename %>
            </p>
            <a class="delete" aria-label="close" data-bulma-modal="close" href="#" phx-click="close_preview_modal"></a>
          </header>

          <section class="modal-card-body">

          </section>

          <footer class="modal-card-foot">
            <a class="button" data-bulma-modal="close" href="#" phx-click="close_preview_modal"><%= gettext("Close") %></a>
          </footer>
        </div>
      </div>
    """
  end
end
