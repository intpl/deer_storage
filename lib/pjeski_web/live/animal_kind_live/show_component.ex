defmodule PjeskiWeb.AnimalKindLive.ShowComponent do
  use Phoenix.LiveComponent
  import PjeskiWeb.Gettext

  def render(assigns) do
    ~L"""
    <section class="hero" id="<%= @animal_kind.id %>">
      <div class="hero-body is-paddingless">
        <div class="container">
          <h1 class="title">
            <%= @animal_kind.name %>
          </h1>
          <h3 class="subtitle">
            <a phx-click="edit" phx-value-animal_kind_id="<%= @animal_kind.id %>">
              <%= gettext("Edit") %>
            </a>

            <a phx-click="delete" phx-value-animal_kind_id="<%= @animal_kind.id %>" data-confirm="<%= gettext("Are you sure to REMOVE this animal_kind?") %>">
              <%= gettext("Delete") %>
            </a>
          </h3>
          <ul>
              <li>
                  <strong>Notes:</strong>
                  <%= @animal_kind.notes %>
              </li>
          </ul>
        </div>
      </div>
    </section>
    </div>
    """
  end
end
