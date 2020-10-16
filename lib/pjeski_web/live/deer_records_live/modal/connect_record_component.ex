defmodule PjeskiWeb.DeerRecordsLive.Modal.ConnectRecordComponent do
  use Phoenix.LiveComponent

  import PjeskiWeb.Gettext

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
                    <p class="control is-expanded">
                      <input
                        class="input"
                        name="query"
                        type="text"
                        list="matches"
                        placeholder="<%= gettext("Search...") %>"
                        value="<%= @connecting_record_query %>"
                        onkeypress="window.scrollTo(0,0)"
                        phx-debounce="300" />
                    </p>
                  </form>
                </p>
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
