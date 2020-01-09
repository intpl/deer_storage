defmodule PjeskiWeb.AnimalBreedLive.ShowComponent do
  use Phoenix.LiveComponent
  import PjeskiWeb.Gettext

  def render(assigns) do
    ~L"""
    <section class="hero" id="<%= @animal_breed.id %>">
      <div class="hero-body is-paddingless">
        <div class="container">
          <h1 class="title">
            <%= @animal_breed.name %>
          </h1>
          <h3 class="subtitle">
            <a phx-click="edit" phx-value-animal_breed_id="<%= @animal_breed.id %>">
              <%= gettext("Edit") %>
            </a>

            <a phx-click="delete" phx-value-animal_breed_id="<%= @animal_breed.id %>" data-confirm="<%= gettext("Are you sure to REMOVE this animal breed?") %>">
              <%= gettext("Delete") %>
            </a>
          </h3>
          <ul>
              <li>
                  <strong><%= gettext("Animal Kind") %></strong>
                  <%= @animal_breed.animal_kind.name %>
              </li>

              <li>
                  <strong><%= gettext("Notes") %></strong>
                  <%= @animal_breed.notes %>
              </li>
          </ul>
        </div>
      </div>
    </section>
    </div>
    """
  end
end
