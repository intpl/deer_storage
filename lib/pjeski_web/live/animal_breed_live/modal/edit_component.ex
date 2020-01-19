defmodule PjeskiWeb.AnimalBreedLive.Modal.EditComponent do
  use Phoenix.LiveComponent
  import PjeskiWeb.Gettext
  import Phoenix.HTML.Form

  def render(%{changeset: changeset, animal_kinds_options: animal_kinds_options} = assigns) do
    ~L"""
      <div class="modal is-active" id="editing_animal_breed">
        <div class="modal-background"></div>
        <div class="modal-card">
          <header class="modal-card-head">
            <p class="modal-card-title">
              <%= gettext("Edit animal breed") %>
            </p>
            <button class="delete" aria-label="close" data-bulma-modal="close" phx-click="close_edit"></button>
          </header>
          <%= form_for changeset, "#", [phx_change: :validate_edit, phx_submit: :save_edit], fn f -> %>
            <section class="modal-card-body">
              <%= PjeskiWeb.AnimalBreedView.render("_form_inputs.html", f: f, animal_kinds_options: animal_kinds_options, selected: changeset.data.animal_kind_id) %>
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
end