defmodule PjeskiWeb.SubscriptionNavigationLive do
  alias PjeskiWeb.Router.Helpers, as: Routes
  alias Phoenix.PubSub

  import PjeskiWeb.Gettext
  import Phoenix.HTML.Link, only: [link: 2]
  import PjeskiWeb.LayoutView, only: [
    compact_tables_to_ids_and_names: 1,
    maybe_active_dashboard_link: 2,
    maybe_active_records_link: 3
  ]

  import PjeskiWeb.LiveHelpers, only: [list_new_table_ids: 2]

  import GenServer, only: [call: 2]
  use Phoenix.LiveView

  def mount(:not_mounted_at_router, %{"missing_subscription" => true, "locale" => locale}, socket) do
    Gettext.put_locale(PjeskiWeb.Gettext, locale)

    {:ok, assign(socket, :missing_subscription, true)}
  end

  # TODO: limit of a cookie is 4k, it is a lot more here...
  def mount(:not_mounted_at_router,
    %{"header_text" => header_text,
      "subscription_id" => subscription_id,
      "subscription_tables" => subscription_tables,
      "storage_limit_kilobytes" => storage_limit_kilobytes,
      "locale" => locale
    }, socket) do

    subscription_tables = subscription_tables || []

    # TODO: refactor this
    records_table_id = if connected?(socket) do
      PubSub.subscribe(Pjeski.PubSub, "subscription:#{subscription_id}")
      PubSub.subscribe(Pjeski.PubSub, "subscription_deer_storage:#{subscription_id}")

      for %{id: id} <- subscription_tables do
        PubSub.subscribe(Pjeski.PubSub, "records_counts:#{id}")
      end

     if socket.root_view == PjeskiWeb.DeerRecordsLive.Index, do: call(socket.root_pid, :whats_my_table_id)
    end

    Gettext.put_locale(PjeskiWeb.Gettext, locale)
    {_files, used_storage_kilobytes} = DeerCache.SubscriptionStorageCache.fetch_data(subscription_id)

    {:ok, assign(socket,
        subscription_tables: fetch_cached_counts(subscription_tables),
        used_storage_kilobytes: used_storage_kilobytes,
        storage_limit_megabytes: ceil(storage_limit_kilobytes / 1024),
        header_text: header_text,
        records_table_id: records_table_id
      )
    }
  end

  def render(%{missing_subscription: true} = assigns) do
    ~L"""
      <div class="navbar-brand">
        <div class="navbar-item">
          <%= gettext("No database assigned") %>
        </div>

        <a role="button" class="navbar-burger burger" aria-label="menu" aria-expanded="false" data-target="navigation">
          <span aria-hidden="true"></span>
          <span aria-hidden="true"></span>
          <span aria-hidden="true"></span>
        </a>
      </div>

      <div id="navigation" class="navbar-menu" phx-hook="hookBurgerEvents">
        <div class="navbar-end">
          <div class="navbar-item">
            <div class="buttons">
              <%= link gettext("Settings"), to: Routes.registration_path(@socket, :edit), method: :get, class: "button is-dark navbar-item" %>
              <%= link gettext("Sign out"), to: Routes.session_path(@socket, :delete), method: :delete, class: "button is-link navbar-item" %>
            </div>
          </div>
        </div>
      </div>
    """
  end

  def render(assigns) do
    ~L"""
      <div class="navbar-brand">
        <%= maybe_active_dashboard_link(@socket, @header_text) %>

        <a role="button" class="navbar-burger burger" aria-label="menu" aria-expanded="false" data-target="navigation">
          <span aria-hidden="true"></span>
          <span aria-hidden="true"></span>
          <span aria-hidden="true"></span>
        </a>
      </div>

      <div id="navigation" class="navbar-menu" phx-hook="hookBurgerEvents">
        <div class="navbar-start">
          <%=
            for dt <- @subscription_tables, do: maybe_active_records_link(@socket, dt, @records_table_id)
          %>
        </div>

        <div class="navbar-end">
          <div class="navbar-item">
            <div class="buttons">
              <button class="button navbar-item is-dark" disabled>
                <%= gettext(
                  "%{used_space} MB used out of %{available_space} MB",
                  used_space: Float.ceil(@used_storage_kilobytes / 1024, 2),
                  available_space: @storage_limit_megabytes
                ) %>
              </button>
              <%= link gettext("Settings"), to: Routes.registration_path(@socket, :edit), method: :get, class: "button is-dark navbar-item" %>
              <%= link gettext("Sign out"), to: Routes.session_path(@socket, :delete), method: :delete, class: "button is-link navbar-item" %>
            </div>
          </div>
        </div>
      </div>
    """
  end

  def handle_info({:cached_deer_storage_changed, {_files, kilobytes}}, socket), do: {:noreply, assign(socket, used_storage_kilobytes: kilobytes)}

  def handle_info({:cached_records_count_changed, table_id, count}, %{assigns: %{subscription_tables: tables}} = socket) do
  socket = socket |> assign(subscription_tables: overwrite_cached_count(tables, table_id, count), __changed__: %{subscription_tables: true})
    {:noreply, socket}
  end

  def handle_info({:subscription_updated, subscription}, %{assigns: %{subscription_tables: old_tables}} = socket) do
    new_tables = compact_tables_to_ids_and_names(subscription.deer_tables)

    list_new_table_ids(old_tables, new_tables)
    |> Enum.each(fn id -> PubSub.subscribe(Pjeski.PubSub, "records_counts:#{id}") end)

    # TODO subscribe to newly added table
    {:noreply, socket |> assign(
      subscription_tables: fetch_cached_counts(new_tables), # non optimal
      storage_limit_megabytes: ceil(subscription.storage_limit_kilobytes / 1024),
      header_text: subscription.name)}
  end

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
