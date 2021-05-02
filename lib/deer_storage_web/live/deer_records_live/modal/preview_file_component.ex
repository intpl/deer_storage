defmodule DeerStorageWeb.DeerRecordsLive.Modal.PreviewFileComponent do
  use Phoenix.LiveComponent
  import DeerStorageWeb.DeerRecordView, only: [render: 2]

  # images
  def render(%{deer_file: %{mimetype: "image/jpeg"}} = assigns), do: render("preview_modal_image.html", assigns)
  def render(%{deer_file: %{mimetype: "image/png"}} = assigns), do: render("preview_modal_image.html", assigns)
  def render(%{deer_file: %{mimetype: "image/gif"}} = assigns), do: render("preview_modal_image.html", assigns)

  # videos
  def render(%{deer_file: %{mimetype: "video/x-flv"}} = assigns), do: render("preview_modal_video.html", assigns)
  def render(%{deer_file: %{mimetype: "video/mp4"}} = assigns), do: render("preview_modal_video.html", assigns)
  def render(%{deer_file: %{mimetype: "video/3gpp"}} = assigns), do: render("preview_modal_video.html", assigns)
  def render(%{deer_file: %{mimetype: "video/quicktime"}} = assigns), do: render("preview_modal_video.html", assigns)
  def render(%{deer_file: %{mimetype: "video/x-msvideo"}} = assigns), do: render("preview_modal_video.html", assigns)
  def render(%{deer_file: %{mimetype: "video/x-ms-wmv"}} = assigns), do: render("preview_modal_video.html", assigns)
  def render(%{deer_file: %{mimetype: "video/webm"}} = assigns), do: render("preview_modal_video.html", assigns)

  # documents
  def render(%{deer_file: %{mimetype: "application/pdf"}} = assigns), do: render("preview_modal_document.html", assigns)
  def render(%{deer_file: %{mimetype: "application/vnd.oasis.opendocument.text"}} = assigns), do: render("preview_modal_document.html", assigns)
  def render(%{deer_file: %{mimetype: "application/vnd.oasis.opendocument.spreadsheet"}} = assigns), do: render("preview_modal_document.html", assigns)
  def render(%{deer_file: %{mimetype: "application/vnd.oasis.opendocument.presentation"}} = assigns), do: render("preview_modal_document.html", assigns)

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
