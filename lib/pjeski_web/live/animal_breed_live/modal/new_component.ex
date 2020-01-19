defmodule PjeskiWeb.AnimalBreedLive.Modal.NewComponent do
  use Phoenix.LiveComponent
  import PjeskiWeb.Gettext
  import Phoenix.HTML.Form

  def render(%{changeset: changeset, animal_kinds_options: animal_kinds_options, selected: selected} = assigns) do
    ~L"""
      <div class="modal is-active" id="new_animal_breed">
        <div class="modal-background"></div>
        <div class="modal-card">
          <header class="modal-card-head">
            <p class="modal-card-title">
              <%= gettext("New animal breed") %>
            </p>
            <button class="delete" aria-label="close" data-bulma-modal="close" phx-click="close_new"></button>
          </header>
          <%= form_for changeset, "#", [phx_submit: :save_new], fn f -> %>
            <section class="modal-card-body">
              <%= PjeskiWeb.AnimalBreedView.render("_form_inputs.html", f: f, animal_kinds_options: animal_kinds_options, selected: selected) %>
            </section>

            <footer class="modal-card-foot">
              <%= submit gettext("Create animal breed"), class: "button is-success", onclick: "window.scrollTo(0,0)" %>
              <a class="button" data-bulma-modal="close" phx-click="close_new"><%= gettext("Cancel") %></a>
            </footer>
          <% end %>
        </div>
      </div>
    """
  end
end
