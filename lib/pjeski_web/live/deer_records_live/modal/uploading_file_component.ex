defmodule PjeskiWeb.DeerRecordsLive.Modal.UploadingFileComponent do
  use Phoenix.LiveComponent
  import PjeskiWeb.Gettext
  import PjeskiWeb.DeerRecordView, only: [display_filesize_from_kilobytes: 1]

  def render(%{record: _record, uploads: uploads} = assigns) do
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
              <a href="#" phx-click="cancel_upload_entry" phx-value-ref="<%= entry.ref %>"> <%= gettext("Cancel") %> </a> |

              <%= entry.client_name %>

              <%= case entry do %>
                <% %{progress: 100} -> %>
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
          </section>

          <footer class="modal-card-foot">
            <a class="button" data-bulma-modal="close" href="#" phx-click="close_upload_file_modal"><%= gettext("Close") %></a>
          </footer>
        </div>
      </div>
    """
  end

  defp translate_error(:too_large), do: gettext("File size exceeds your subscription limits")

  defp errors_for_entry([], _), do: nil
  defp errors_for_entry(errors, %{ref: ref}), do: Enum.find(errors, fn {error_ref, _error} -> error_ref == ref end)
end
