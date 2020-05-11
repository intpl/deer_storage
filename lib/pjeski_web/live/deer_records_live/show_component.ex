defmodule PjeskiWeb.DeerRecordsLive.ShowComponent do
  use Phoenix.LiveComponent
  import PjeskiWeb.Gettext

  def render(assigns) do
    ~L"""
    <section class="hero" id="<%= @record.id %>">
      <div class="hero-body is-paddingless">
        <div class="container">
          <h1 class="title">
            <%= @record.name %>
          </h1>
          <h3 class="subtitle">
            <a phx-click="edit" phx-value-record_id="<%= @record.id %>">
              <%= gettext("Edit") %>
            </a>

            <a phx-click="delete" phx-value-record_id="<%= @record.id %>" data-confirm="<%= gettext("Are you sure to REMOVE this record?") %>">
              <%= gettext("Delete") %>
            </a>
          </h3>
          <ul>
              <li>
                  <strong>Phone:</strong>
                  <%= @record.phone %>
              </li>

              <li>
                  <strong>Email:</strong>
                  <%= @record.email %>
              </li>

              <li>
                  <strong>City:</strong>
                  <%= @record.city %>
              </li>

              <li>
                  <strong>Address:</strong>
                  <%= @record.address %>
              </li>

              <li>
                  <strong>Notes:</strong>
                  <%= @record.notes %>
              </li>
          </ul>
        </div>
      </div>
    </section>
    </div>
    """
  end
end
