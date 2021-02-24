defmodule PjeskiWeb.DeerRecordsLive.Modal.PreviewFileComponent do
  use Phoenix.LiveComponent
  import PjeskiWeb.Gettext
  import PjeskiWeb.DeerRecordView, only: [maybe_shrink_filename: 2]

  def render(assigns) do
    ~L"""
      <div class="modal is-active" phx-window-keydown="key" phx-target="<%= @myself %>" phx-hook="hookPreviewGestures">
        <a class="modal-background" phx-click="close_preview_modal" phx-target="<%= @myself %>" style="cursor: default;"></a>

        <div class="buttons has-addons is-centered is-hidden-mobile">
          <a class="button is-dark" phx-click="previous" phx-target="<%= @myself %>" href="#">
            <%= gettext("Previous") %>
          </a>
          <a class="button is-dark" phx-click="next" phx-target="<%= @myself %>" href="#">
            <%= gettext("Next") %>
          </a>
        </div>
        <div class="has-text-white modal-content has-text-centered" id="divLoading">
          <br> <%= gettext("Loading") %>...
        </div>

        <p class="image">
          <img id="imagePreview" src="<%= @image_url %>" class="image-inside-modal-overwrite">
        </p>

        <div class="modal-content has-text-centered">
          <span class="has-text-white"><%= maybe_shrink_filename(@original_filename, 30) %></span>
        </div>
        <a class="modal-close is-large" data-bulma-modal="close" href="#" phx-target="<%= @myself %>" phx-click="close_preview_modal"><%= gettext("Close") %></a>
      </div>
    """
  end

  def handle_event("close_preview_modal", _, socket) do
    send(self(), :close_preview_modal)
    {:noreply, socket}
  end

  def handle_event("previous", _, socket), do: send_previous_file() && {:noreply, socket}
  def handle_event("next", _, socket), do: send_next_file() && {:noreply, socket}
  def handle_event("key", %{"key" => "Escape"}, socket), do: send(self(), :close_preview_modal) && {:noreply, socket}
  def handle_event("key", %{"key" => "ArrowLeft"}, socket), do: send_previous_file() && {:noreply, socket}
  def handle_event("key", %{"key" => "ArrowRight"}, socket), do: send_next_file() && {:noreply, socket}
  def handle_event("key", %{"key" => _}, socket), do: {:noreply, socket}

  defp send_previous_file(), do: send(self(), :preview_previous_file)
  defp send_next_file(), do: send(self(), :preview_next_file)
end
