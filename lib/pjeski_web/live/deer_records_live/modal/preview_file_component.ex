defmodule PjeskiWeb.DeerRecordsLive.Modal.PreviewFileComponent do
  use Phoenix.LiveComponent
  import PjeskiWeb.DeerRecordView, only: [render: 2]

  def render(%{deer_file: %{mimetype: "image/jpeg"}} = assigns), do: render("preview_modal_image.html", assigns)
  def render(%{deer_file: %{mimetype: "image/png"}} = assigns), do: render("preview_modal_image.html", assigns)
  def render(%{deer_file: %{mimetype: "image/gif"}} = assigns), do: render("preview_modal_image.html", assigns)

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
