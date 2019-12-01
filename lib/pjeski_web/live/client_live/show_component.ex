defmodule PjeskiWeb.ClientLive.ShowComponent do
  use Phoenix.LiveComponent
  import PjeskiWeb.Gettext

  def render(assigns) do
    ~L"""
    <section class="hero" id="<%= @client.id %>">
      <div class="hero-body is-paddingless">
        <div class="container">
          <h1 class="title">
            <%= @client.name %>
          </h1>
          <h3 class="subtitle">
            <a phx-click="<%= @edit_click %>" phx-value-client_id="<%= @client.id %>">
              <%= gettext("Edit") %>
            </a>
          </h3>
          <ul>
              <li>
                  <strong>Phone:</strong>
                  <%= @client.phone %>
              </li>

              <li>
                  <strong>Email:</strong>
                  <%= @client.email %>
              </li>

              <li>
                  <strong>City:</strong>
                  <%= @client.city %>
              </li>

              <li>
                  <strong>Address:</strong>
                  <%= @client.address %>
              </li>

              <li>
                  <strong>Notes:</strong>
                  <%= @client.notes %>
              </li>
          </ul>
        </div>
      </div>
    </section>
    </div>
    """
  end
end
