defmodule PjeskiWeb.AnimalLive.ShowComponent do
  use Phoenix.LiveComponent
  import PjeskiWeb.Gettext

  def render(assigns) do
    ~L"""
    <section class="hero" id="<%= @animal.id %>">
      <div class="hero-body is-paddingless">
        <div class="container">
          <h1 class="title">
            <%= @animal.name %>
          </h1>
          <h3 class="subtitle">
            <a phx-click="edit" phx-value-animal_id="<%= @animal.id %>">
              <%= gettext("Edit") %>
            </a>

            <a phx-click="delete" phx-value-animal_id="<%= @animal.id %>" data-confirm="<%= gettext("Are you sure to REMOVE this animal") %>">
              <%= gettext("Delete") %>
            </a>
          </h3>
          <ul>
              <li>
                  <strong><%= gettext("Animal Kind") %></strong>
                  <%= @animal.animal_kind.name %>
              </li>

              <li>
                  <strong><%= gettext("Notes") %></strong>
                  <%= @animal.notes %>
              </li>
          </ul>
        </div>
      </div>
    </section>
    </div>
    """
  end
end
