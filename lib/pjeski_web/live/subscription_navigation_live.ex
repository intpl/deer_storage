defmodule PjeskiWeb.SubscriptionNavigationLive do
  alias PjeskiWeb.Router.Helpers, as: Routes
  alias Phoenix.PubSub

  import PjeskiWeb.Gettext
  import Phoenix.HTML.Link, only: [link: 2]

  use Phoenix.LiveView

  # TODO: limit of a cookie is 4k, it is a lot more here...
  def mount(:not_mounted_at_router,
    %{"header_text" => header_text,
      "subscription_id" => subscription_id,
      "subscription_tables" => subscription_tables
    }, socket) do
    if connected?(socket) && subscription_id != nil, do: PubSub.subscribe(Pjeski.PubSub, "subscription:#{subscription_id}")

    {:ok, assign(socket, subscription_tables: subscription_tables, header_text: header_text)}
  end

  def render(assigns) do
    ~L"""
      <div class="navbar-brand">
        <%= live_redirect(
            @header_text,
            to: Routes.live_path(PjeskiWeb.Endpoint, PjeskiWeb.DeerDashboardLive.Index),
            class: "navbar-item") %>

        <a role="button" class="navbar-burger burger" aria-label="menu" aria-expanded="false" data-target="navigation">
          <span aria-hidden="true"></span>
          <span aria-hidden="true"></span>
          <span aria-hidden="true"></span>
        </a>
      </div>

      <div id="navigation" class="navbar-menu">
        <div class="navbar-start">
          <%= for %{name: table_name, id: table_id} <- @subscription_tables do %>
            <%= live_redirect table_name, to: Routes.live_path(@socket, PjeskiWeb.DeerRecordsLive.Index, table_id), class: "navbar-item" %>
          <% end %>
        </div>

        <div class="navbar-end">
          <div class="navbar-item">
            <div class="buttons">
              <%= link gettext("Settings"), to: Routes.registration_path(PjeskiWeb.Endpoint, :edit), method: :get, class: "button is-dark navbar-item" %>
              <%= link gettext("Sign out"), to: Routes.session_path(PjeskiWeb.Endpoint, :delete), method: :delete, class: "button is-link navbar-item" %>
            </div>
          </div>
        </div>
      </div>
    """
  end

  def handle_info({:subscription_updated, subscription}, socket), do: {
    :noreply, socket |> assign(
      subscription_tables: subscription.deer_tables,
      header_text: subscription.name
    )
  }
end
