defmodule PjeskiWeb.DeerDashboardLive.DeerTableComponent do
  use Phoenix.LiveComponent

  import PjeskiWeb.Gettext
  import Phoenix.HTML.Form

  def render(%{table: %{name: table_name, deer_columns: deer_columns}} = assigns) do
    ~L"""
    <div class="box">
      <article class="media">
        <div class="media-content">
          <div class="content">
            <p>
              <strong><%= table_name %></strong><br>

              <%= for %{name: name} <- deer_columns do %>
                <%= name %><br>
              <% end %>
            </p>
          </div>
        </div>
      </article>
    </div>
    """
  end
end
