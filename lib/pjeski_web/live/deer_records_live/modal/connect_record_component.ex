defmodule PjeskiWeb.DeerRecordsLive.Modal.ConnectRecordComponent do
  use Phoenix.LiveComponent

  import PjeskiWeb.DeerRecordView
  import PjeskiWeb.Gettext

  def update(%{
        subscription: %{deer_tables: deer_tables} = subscription,
        excluded_records_ids: excluded_record_ids,
        connecting_record_query: query,
        connecting_record_records: records,
        connecting_record_selected_table_id: table_id}, socket) do

    {:ok, assign(socket,
      deer_columns: deer_columns_from_subscription(subscription, table_id),
      deer_tables: deer_tables,
      table_id: table_id,
      records: records,
      query: query
    )}
  end

  def render(assigns) do
    ~L"""
      <div class="modal is-active">
        <div class="modal-background"></div>
        <div class="modal-card">
          <header class="modal-card-head">
            <p class="modal-card-title">
              <%= gettext("Connect record") %>
            </p>
            <a class="delete" aria-label="close" data-bulma-modal="close" href="#" phx-click="close_connecting_record"></a>
          </header>

          <section class="modal-card-body">
            <div class="column is-8">
              <div class="field has-addons">
                <p class="is-fullwidth">
                  <form phx-change="connecting_record_filter" class="field has-addons overwrite-fullwidth">
                    <p class="control">
                      <span class="select">
                        <select name="table_id">
                          <%= for %{id: id, name: name} <- @deer_tables do %>
                            <option value="<%= id %>" <%= if @table_id == id, do: "selected" %>>
                              <%= name %>
                            </option>
                          <% end %>
                        </select>
                      </span>
                    </p>
                    <p class="control is-expanded">
                      <input
                        class="input"
                        name="query"
                        type="text"
                        list="matches"
                        placeholder="<%= gettext("Search...") %>"
                        value="<%= @query %>"
                        onkeypress="window.scrollTo(0,0)"
                        phx-debounce="300" />
                    </p>
                  </form>
                </p>
              </div>
            </div>
            <div class="columns is-mobile">
              <div class="column">
                <%= for record <- @records do %>
                  <a class="box" href="#" phx-click="connect_records" phx-value-record_id="<%= record.id %>">
                    <article class="media">
                      <div class="media-content">
                        <div class="content">
                          <%= for %{id: column_id, name: column_name} <- @deer_columns do %>
                            <%= column_name %>: <strong><%= deer_field_content_from_column_id(record, column_id) %></strong>
                          <% end %>
                        </div>
                      </div>
                    </article>
                  </a>
                <% end %>
              </div>
            </div>
          </section>

          <footer class="modal-card-foot">
            <a class="button" data-bulma-modal="close" href="#" phx-click="close_connecting_record"><%= gettext("Close") %></a>
          </footer>
        </div>
      </div>
    """
  end
end
