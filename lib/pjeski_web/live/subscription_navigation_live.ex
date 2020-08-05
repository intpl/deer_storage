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
      "subscription_tables" => subscription_tables,
      "locale" => locale
    }, socket) do

    if connected?(socket) && subscription_id != nil do
      PubSub.subscribe(Pjeski.PubSub, "subscription:#{subscription_id}")

      for %{id: id} <- subscription_tables do
        PubSub.subscribe(Pjeski.PubSub, "records_counts:#{id}")
      end
    end

    Gettext.put_locale(PjeskiWeb.Gettext, locale)

    {:ok, assign(socket,
        subscription_tables: fetch_cached_counts(subscription_tables),
        header_text: header_text
      )
    }
  end

  def render(assigns) do
    ~L"""
      <div class="navbar-brand">
        <%= live_redirect(
            @header_text,
            to: Routes.live_path(PjeskiWeb.Endpoint, PjeskiWeb.DeerDashboardLive.Index),
            class: "navbar-item has-text-weight-bold") %>

        <a role="button" class="navbar-burger burger" aria-label="menu" aria-expanded="false" data-target="navigation">
          <span aria-hidden="true"></span>
          <span aria-hidden="true"></span>
          <span aria-hidden="true"></span>
        </a>
      </div>

      <div id="navigation<%= :rand.uniform(200) %>" class="navbar-menu">
        <div class="navbar-start">
          <%= for dt <- @subscription_tables do %>
            <%= live_redirect "#{dt.name} (#{dt.count})", to: Routes.live_path(@socket, PjeskiWeb.DeerRecordsLive.Index, dt.id), class: "navbar-item" %>
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

  def handle_info({:cached_records_count_changed, table_id, count}, %{assigns: %{subscription_tables: tables}} = socket) do
  socket = socket |> assign(subscription_tables: overwrite_cached_count(tables, table_id, count), __changed__: %{subscription_tables: true})
  IO.inspect socket.assigns
    {:noreply, socket}
  end

  def handle_info({:subscription_updated, subscription}, socket), do: {
    # TODO subscribe to newly added table
    :noreply, socket |> assign(
      subscription_tables: fetch_cached_counts(subscription.deer_tables), # lol remove this
      header_text: subscription.name
    )
  }

  defp overwrite_cached_count(tables, table_id, count) do
    target_index = Enum.find_index(tables, fn %{id: id} -> id == table_id end)

    List.update_at(tables, target_index, fn dt -> Map.merge(dt, %{count: count}) end)

  end

  defp fetch_cached_counts(tables) do
    Enum.map(tables, fn %{id: id, name: name} ->
      %{id: id, name: name, count: DeerCache.RecordsCountsCache.fetch_count(id)}
    end)
  end
end
