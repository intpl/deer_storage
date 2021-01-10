defmodule PjeskiWeb.DeerRecordsLive.Modal.UploadingFileComponent do
  use Phoenix.LiveComponent
  import PjeskiWeb.Gettext
  import PjeskiWeb.DeerRecordView, only: [display_filesize_from_kilobytes: 1]

  def render(%{uploads: _uploads} = assigns) do
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
            <%= for entry <- @uploads.deer_file.entries do %>
              <a href="#" phx-click="cancel_upload_entry" phx-value-ref="<%= entry.ref %>"> <%= gettext("Cancel") %> </a>

              | <%= display_filesize_from_kilobytes(ceil(entry.client_size / 1024)) %>
              | <%= entry.client_name %>

              <%= case entry do %>
                <% %{progress: 100} -> %>
                  <span class="has-text-info"> <%= gettext("Waiting for other uploads to complete...") %> </span>
                  <progress class="progress is-success" value="100" max="100">100%</progress>
                <% %{progress: 0} -> %>
                  <%= case errors_for_entry(@uploads.deer_file.errors, entry) do %>
                    <% nil -> %> <progress class="progress is-info" value="0" max="100">0%</progress>
                    <% {_ref, error} -> %>
                      <br>
                      <span class="has-text-danger"> <%= translate_error(error) %> </span>

                      <progress class="progress is-danger" value="100" max="100">0%</progress>
                  <% end %>
                <% _ -> %>
                  <progress class="progress is-info" value="<%= entry.progress %>" max="100"><%= entry.progress %>%</progress>
              <% end %>

            <br>
            <% end %>

            <form phx-submit="submit_upload" phx-change="validate_upload" class="file is-centered">
              <label class="file">
              <%= Phoenix.LiveView.Helpers.live_file_input @uploads.deer_file, class: "file-input" %>
                <span class="file-cta">
                  <span class="file-label">
                    <%= gettext("Select file(s) to upload") %>
                  </span>
                </span>
              </label>
              <%= if Enum.any?(@uploads.deer_file.entries) do %><button type="submit" class="button is-primary"><%= gettext("Upload file(s)") %></button><% end %>
            </form>

            <%= for result <- @upload_results do %>
              <%= case result do %>
                <% {:ok, filename} -> %><span class="has-text-success"><%= gettext("File '%{filename}' uploaded successfuly", filename: filename) %></span>
                <% {:error, filename} -> %><span class="has-text-danger"><%= gettext("File '%{filename}' could not be uploaded (space limit exceeded?)", filename: filename) %></span>
                <% :total_size_exceeds_limits -> %><span class="has-text-danger"><%= translate_error(:total_size_exceeds_limits) %></span>
              <% end %>
              <br>
            <% end %>

          </section>

          <footer class="modal-card-foot">
            <a class="button" data-bulma-modal="close" href="#" phx-click="close_upload_file_modal"><%= gettext("Close") %></a>
          </footer>
        </div>
      </div>
    """
  end

  defp translate_error(:too_large), do: gettext("File size exceeds your subscription limits")
  defp translate_error(:total_size_exceeds_limits), do: gettext("Upload has been canceled due to the total size of files exceeded subscription limits")

  defp errors_for_entry([], _), do: nil
  defp errors_for_entry(errors, %{ref: ref}), do: Enum.find(errors, fn {error_ref, _error} -> error_ref == ref end)
end
