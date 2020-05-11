defmodule PjeskiWeb.DeerRecordsLive.Modal.EditComponent do
  use Phoenix.LiveComponent
  import PjeskiWeb.Gettext
  import Phoenix.HTML.Form

  def render(%{changeset: changeset} = assigns) do
    ~L"""
      <div class="modal is-active" id="editing_record">
        <div class="modal-background"></div>
        <div class="modal-card">
          <header class="modal-card-head">
            <p class="modal-card-title">
              <%= gettext("Edit record") %>
            </p>
            <button class="delete" aria-label="close" data-bulma-modal="close" phx-click="close_edit"></button>
          </header>
          <%= form_for changeset, "#", [phx_change: :validate_edit, phx_submit: :save_edit], fn f -> %>
            <section class="modal-card-body">
              <%= PjeskiWeb.DeerRecordView.render("_form_inputs.html", f: f) %>
            </section>

            <footer class="modal-card-foot">
              <%= if changeset.valid? do %>
                <%= submit gettext("Save changes"), class: "button is-success", onclick: "window.scrollTo(0,0)" %>
              <% end %>

              <a class="button" data-bulma-modal="close" phx-click="close_edit"><%= gettext("Cancel") %></a>
            </footer>
          <% end %>
        </div>
      </div>
    """
  end

  def handle_event("save", %{"record" => record_attrs}, socket) do
    send self(), {:save_edit, record_attrs}
    {:noreply, socket}
  end

  def handle_event("validate", %{"record" => record_attrs}, socket) do
    send self(), {:validate_edit, record_attrs}
    {:noreply, socket}
  end

  def handle_event("close", _, socket) do
    send self(), :close_edit

    {:noreply, socket}
  end
end
