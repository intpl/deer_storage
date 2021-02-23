defmodule PjeskiWeb.DeerRecordsLive.Modal.PreviewFileComponent do
  use Phoenix.LiveComponent
  import PjeskiWeb.Gettext
  import PjeskiWeb.DeerRecordView, only: [maybe_shrink_filename: 2]

  def render(assigns) do
    ~L"""
      <div class="modal is-active" phx-window-keydown="key" phx-target="<%= @myself %>" phx-hook="hookPreviewGestures">
        <a class="modal-background" phx-click="close_preview_modal" phx-target="<%= @myself %>" style="cursor: default;"></a>
        <div class="modal-content">
          <p class="image">
            <img src="<%= @image_url %>" class="image-inside-modal-overwrite">
            <span class="has-text-white"><%= maybe_shrink_filename(@original_filename, 30) %></span>
          </p>
        </div>
        <a class="modal-close is-large" data-bulma-modal="close" href="#" phx-target="<%= @myself %>" phx-click="close_preview_modal"><%= gettext("Close") %></a>
      </div>
    """
  end

  def handle_event("close_preview_modal", _, socket) do
    send(self(), :close_preview_modal)
    {:noreply, socket}
  end

  def handle_event("key", %{"key" => "Escape"}, socket) do
    send(self(), :close_preview_modal)
    {:noreply, socket}
  end

  def handle_event("key", %{"key" => "ArrowLeft"}, socket) do
    send_previous_file()
    {:noreply, socket}
  end

  def handle_event("key", %{"key" => "ArrowRight"}, socket) do
    send_next_file()
    {:noreply, socket}
  end

  def handle_event("key", %{"key" => _}, socket), do: {:noreply, socket}

  defp send_previous_file(), do: send(self(), :preview_previous_file)
  defp send_next_file(), do: send(self(), :preview_next_file)
end
