defmodule PjeskiWeb.ClientLive.Modal.EditComponent do
  use Phoenix.LiveComponent
  import PjeskiWeb.Gettext
  import Phoenix.HTML.Form
  import PjeskiWeb.ErrorHelpers

  def render(%{changeset: changeset} = assigns) do
    ~L"""
      <div class="modal is-active" id="editing_client">
        <div class="modal-background"></div>
        <div class="modal-card">
          <header class="modal-card-head">
            <p class="modal-card-title"><%= gettext("Editing: ") %><%= changeset.data.name %></p>
            <button class="delete" aria-label="close" data-bulma-modal="close" phx-click="close"></button>
          </header>
          <%= f = form_for changeset, "#", [phx_change: :validate, phx_submit: :save] %>
            <section class="modal-card-body">
            <div class"container">
              <div class="field is-horizontal">
                <%= label f, gettext("Name"), class: 'label field-label' %>
                <div class="field-body">
                  <div class="field">
                    <%= text_input f, :name, class: 'input' %>
                    <%= error_tag f, :name %>
                  </div>
                </div>
              </div>

              <div class="field is-horizontal">
                <%= label f, gettext("Phone number"), class: 'label field-label' %>
                <div class="field-body">
                  <div class="field">
                    <%= text_input f, :phone, class: 'input' %>
                    <%= error_tag f, :phone %>
                  </div>
                </div>
              </div>

              <div class="field is-horizontal">
                <%= label f, gettext("Email"), class: 'label field-label' %>
                <div class="field-body">
                  <div class="field">
                    <%= text_input f, :email, class: 'input' %>
                    <%= error_tag f, :email %>
                  </div>
                </div>
              </div>

              <div class="field is-horizontal">
                <%= label f, gettext("City"), class: 'label field-label' %>
                <div class="field-body">
                  <div class="field">
                    <%= text_input f, :city, class: 'input' %>
                    <%= error_tag f, :city %>
                  </div>
                </div>
              </div>

              <div class="field is-horizontal">
                <%= label f, gettext("Address"), class: 'label field-label' %>
                <div class="field-body">
                  <div class="field">
                    <%= text_input f, :address, class: 'input' %>
                    <%= error_tag f, :address %>
                  </div>
                </div>
              </div>

              <div class="field is-horizontal">
                <%= label f, gettext("Notes"), class: 'label field-label' %>
                <div class="field-body">
                  <div class="field">
                    <%= textarea f, :notes, class: 'textarea', rows: 5 %>
                    <%= error_tag f, :notes %>
                  </div>
                </div>
              </div>
              </div>
            </section>

            <footer class="modal-card-foot">
              <%= submit gettext("Save changes"), class: "button is-success" %>
              <a class="button" data-bulma-modal="close" phx-click="close"><%= gettext("Cancel") %></a>
            </footer>
          </form>
        </div>
      </div>
    """
  end

  def handle_event("save", %{"client" => client_attrs}, socket) do
    send self(), {:save_edit_modal, client_attrs, socket}
    {:noreply, socket}
  end

  def handle_event("validate", %{"client" => client_attrs}, socket) do
    send self(), {:validate_edit_modal, client_attrs, socket}
    {:noreply, socket}
  end

  def handle_event("close", _, socket) do
    send self(), :close_edit_modal

    {:noreply, socket}
  end
end
