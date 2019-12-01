defmodule PjeskiWeb.ClientLive.ClientComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~L"""
    <section class="hero" id="<%= @client.id %>">
      <div class="hero-body is-paddingless">
        <div class="container">
          <h1 class="title">
            <%= @client.name %>
          </h1>
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
