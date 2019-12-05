defmodule PjeskiWeb.AnimalKindLive.Modal.NewComponent do
  use Phoenix.LiveComponent
  import PjeskiWeb.Gettext
  import Phoenix.HTML.Form

  def render(%{changeset: changeset} = assigns) do
    ~L"""
      <div class="modal is-active" id="new_animal_kind">
        <div class="modal-background"></div>
        <div class="modal-card">
          <header class="modal-card-head">
            <p class="modal-card-title">
              <%= gettext("New animal kind") %>
            </p>
            <button class="delete" aria-label="close" data-bulma-modal="close" phx-click="close"></button>
          </header>
          <%= form_for changeset, "#", [phx_submit: :save], fn f -> %>
            <section class="modal-card-body">
              <%= PjeskiWeb.AnimalKindView.render("_form_inputs.html", f: f) %>
            </section>

            <footer class="modal-card-foot">
              <%= submit gettext("Create animal kind"), class: "button is-success", onclick: "window.scrollTo(0,0)" %>
              <a class="button" data-bulma-modal="close" phx-click="close"><%= gettext("Cancel") %></a>
            </footer>
          <% end %>
        </div>
      </div>
    """
  end

  def handle_event("save", %{"animal_kind" => animal_kind_attrs}, socket) do
    send self(), {:save_new, animal_kind_attrs}
    {:noreply, socket}
  end

  def handle_event("close", _, socket) do
    send self(), :close_new

    {:noreply, socket}
  end
end
