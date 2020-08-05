defmodule PjeskiWeb.DeerRecordsLive.Index do
  use Phoenix.LiveView

  alias PjeskiWeb.Router.Helpers, as: Routes
  import PjeskiWeb.Gettext

  import Pjeski.Users.UserSessionUtils, only: [get_live_user: 2]
  import PjeskiWeb.LiveHelpers, only: [
    append_missing_fields_to_record: 3,
    is_expired?: 1,
    keys_to_atoms: 1,
    maybe_update_record_in_list: 2,
    maybe_delete_record_in_list: 2,
    toggle_record_in_list: 2
  ]

  alias Phoenix.PubSub
  alias Pjeski.Repo
  alias Pjeski.DeerRecords.DeerRecord
  alias Pjeski.UserAvailableSubscriptionLinks.UserAvailableSubscriptionLink

  import PjeskiWeb.DeerRecordView, only: [deer_table_from_subscription: 2]
  import Pjeski.DeerRecords, only: [
    change_record: 3,
    create_record: 2,
    delete_record: 2,
    get_record!: 2,
    update_record: 3
  ]

  import Pjeski.DbHelpers.DeerRecordsSearch

  def mount(_params, %{"pjeski_auth" => _token, "current_subscription_id" => current_subscription_id} = session, socket) do
    #if connected?(socket), do: :timer.send_interval(30000, self(), :update)
    user = get_live_user(socket, session)

    Gettext.put_locale(user.locale)

    {:ok, assign(socket,
        current_records: [],
        editing_record: nil,
        new_record: nil,
        table_name: nil,
        page: 1,
        per_page: per_page(),
        current_user: user,
        current_subscription: nil,
        current_subscription_id: current_subscription_id,
        current_subscription_name: nil,
        current_subscription_tables: [],
        locale: user.locale
      )}
  end

  def render(assigns), do: PjeskiWeb.DeerRecordView.render("index.html", assigns)

  def handle_params(%{"table_id" => table_id} = params, _, %{assigns: %{current_user: user, current_subscription_id: subscription_id}} = socket) do
    query = params["query"]

    case connected?(socket) do
      true ->
        PubSub.subscribe(Pjeski.PubSub, "record:#{subscription_id}:#{table_id}")
        PubSub.subscribe(Pjeski.PubSub, "subscription:#{subscription_id}")

        user_subscription_link = Repo.get_by!(UserAvailableSubscriptionLink, [user_id: user.id, subscription_id: subscription_id])
        |> Repo.preload(:subscription)
        subscription = user_subscription_link.subscription

        socket = case table_from_subscription(subscription, table_id) do
                   %{name: table_name} -> assign(socket, :table_name, table_name)
                   nil -> push_redirect(socket, to: "/dashboard")
                 end

        case is_expired?(subscription) do
          true -> {:noreply, push_redirect(socket, to: "/registration/edit")}
          false ->
            records = search_records(subscription.id, table_id, query, 1)

            {:noreply,
             socket |> assign(
               count: length(records),
               query: query,
               records: records,
               current_subscription: subscription,
               current_subscription_name: subscription.name,
               current_subscription_tables: subscription.deer_tables,
               table_id: table_id,
               user_subscription_link: user_subscription_link # TODO: permissions
             )}
        end
      false -> {:noreply, socket |> assign(query: query, records: [], count: 0)}
    end
  end

  def handle_event("close_show", %{"id" => id_string}, %{assigns: %{current_records: current_records}} = socket) do
    id = String.to_integer(id_string)

    {:noreply, socket |> assign(current_records: toggle_record_in_list(current_records, %{id: id}))}
  end

  def handle_event("close_new", _, socket), do: {:noreply, socket |> assign(new_record: nil)}
  def handle_event("close_edit", _, socket), do: {:noreply, socket |> assign(editing_record: nil)}

  # TODO refactor
  def handle_event("validate_edit", %{"deer_record" => attrs}, %{assigns: %{editing_record: record, current_subscription: subscription, table_id: table_id}} = socket) do
    attrs = Map.merge(attrs, %{"deer_table_id" => table_id}) |> keys_to_atoms

    {:noreply, socket |> assign(editing_record: change_record(subscription, record.data, attrs))}
  end

  def handle_event("save_edit", %{"deer_record" => attrs}, %{assigns: %{editing_record: record, current_subscription: subscription, table_id: table_id}} = socket) do
    attrs = Map.merge(attrs, %{"deer_table_id" => table_id}) |> keys_to_atoms

    {:ok, _} = update_record(subscription, record.data, attrs)

    # waiting for this to get resolved: https://github.com/phoenixframework/phoenix_live_view/issues/340
    {:noreply, socket |> assign(:editing_record, nil) |> put_flash(:info, gettext("Record updated successfully."))}
  end

  # TODO refactor
  def handle_event("validate_new", %{"deer_record" => attrs}, %{assigns: %{new_record: record, current_subscription: subscription, table_id: table_id}} = socket) do
    attrs = Map.merge(attrs, %{"deer_table_id" => table_id}) |> keys_to_atoms

    {:noreply, socket |> assign(new_record: change_record(subscription, record.data, attrs))}
  end

  def handle_event("save_new", %{"deer_record" => attrs}, %{assigns: %{current_subscription: subscription, table_id: table_id}} = socket) do
    attrs = Map.merge(attrs, %{"deer_table_id" => table_id}) |> keys_to_atoms

    case create_record(subscription, attrs) do
      {:ok, _} ->
        {:noreply, socket |> assign(new_record: nil, query: "")}
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(new_record: changeset)}
    end

  end

  def handle_event("show", %{"record_id" => record_id}, %{assigns: %{records: records, current_records: current_records, current_subscription: subscription}} = socket) do
    record = find_record_in_list_or_database(record_id, records, subscription)

    {:noreply, socket |> assign(current_records: toggle_record_in_list(current_records, record))}
  end

  def handle_event("new", _, %{assigns: %{current_subscription: %{deer_tables: deer_tables} = subscription, table_id: table_id}} = socket) do
    deer_columns = Enum.find(deer_tables, fn table -> table.id == table_id end).deer_columns
    deer_fields_attrs = Enum.map(deer_columns, fn %{id: column_id} -> %{deer_column_id: column_id, content: ""} end)

    {:noreply, socket |> assign(new_record: change_record(subscription, %DeerRecord{}, %{deer_table_id: table_id, deer_fields: deer_fields_attrs}))}
  end

  def handle_event("edit", %{"record_id" => record_id}, %{assigns: %{records: records, current_subscription: subscription, table_id: table_id}} = socket) do
    record = find_record_in_list_or_database(record_id, records, subscription)
    |> append_missing_fields_to_record(table_id, subscription)

    {:noreply, socket |> assign(editing_record: change_record(subscription, record, %{deer_table_id: table_id}))}
  end

  def handle_event("delete", %{"record_id" => record_id}, %{assigns: %{records: records, current_subscription: subscription}} = socket) do
    record = find_record_in_list_or_database(record_id, records, subscription)
    {:ok, _} = delete_record(subscription, record)

    # waiting for this to get resolved: https://github.com/phoenixframework/phoenix_live_view/issues/340
    {:noreply, socket |> put_flash(:info, gettext("Record deleted successfully."))}
  end

  def handle_event("clear", _, %{assigns: %{table_id: table_id, current_subscription_id: subscription_id}} = socket) do
    records = search_records(subscription_id, table_id, "", 1)

    {:noreply, socket |> assign(query: "", page: 1, records: records)}
  end

  def handle_event("filter", %{"query" => query}, %{assigns: %{current_subscription: subscription, table_id: table_id}} = socket) when byte_size(query) <= 50 do
    records = search_records(subscription.id, table_id, query, 1)

    {:noreply, socket |> assign(records: records, query: query, page: 1, count: length(records))}
  end

  def handle_event("submit", %{"query" => query}, socket), do: {:noreply, assign(socket, :query, query)}

  def handle_event("next_page", _, %{assigns: %{page: page}} = socket), do: change_page(page + 1, socket)
  def handle_event("previous_page", _, %{assigns: %{page: page}} = socket), do: change_page(page - 1, socket)

  def handle_info({:record_change, %{id: record_id} = record}, socket) do
    %{current_subscription: current_subscription, table_id: table_id, query: query, page: page, current_records: current_records, editing_record: editing_record} = socket.assigns

    new_editing_record = case editing_record do
                           nil -> nil
                           _ ->
                             case Ecto.Changeset.fetch_field!(editing_record, :id) do
                               ^record_id -> nil
                               ch -> ch
                             end
                         end

    current_records = case record.__meta__.state do
                        :loaded -> maybe_update_record_in_list(current_records, record)
                        :deleted -> maybe_delete_record_in_list(current_records, record)
                        _ -> socket
                      end

    {:noreply, socket |> assign(
        editing_record: new_editing_record,
        current_records: current_records,
        records: search_records(current_subscription.id, table_id, query, page)
      )}
  end

  def handle_info({:subscription_updated, subscription}, %{assigns: %{editing_record: editing_record, new_record: new_record, table_id: table_id}} = socket) do
    case is_expired?(subscription) do
      true -> {:noreply, push_redirect(socket, to: "/registration/edit")}
      false ->
        case deer_table_from_subscription(subscription, table_id) do
          nil -> {:noreply, push_redirect(socket, to: "/dashboard")}
          %{name: name} ->
            socket = socket
            |> assign(
              current_subscription: subscription,
              current_subscription_name: subscription.name,
              current_subscription_tables: subscription.deer_tables,
              table_name: name)
            |> maybe_assign_record_changeset(:new_record, subscription, new_record)
            |> maybe_assign_record_changeset(:editing_record, subscription, editing_record)

            {:noreply, socket}
        end
    end
   end

  defp change_page(new_page, %{assigns: %{current_subscription: subscription, query: query, table_id: table_id}} = socket) do
    records = search_records(subscription.id, table_id, query, new_page)

    {:noreply, socket |> assign(records: records, page: new_page, count: length(records))}
  end

  defp find_record_in_database(id, subscription), do: get_record!(subscription, id)
  defp find_record_in_list_or_database(id, records, subscription) do
    id = id |> String.to_integer

    Enum.find(records, fn record -> record.id == id end) || find_record_in_database(id, subscription)
  end

  defp table_from_subscription(%{deer_tables: deer_tables}, table_id) do
    Enum.find(deer_tables, fn deer_table -> deer_table.id == table_id end)
  end

  defp maybe_assign_record_changeset(socket, _type, _subscription, nil), do: socket
  defp maybe_assign_record_changeset(socket, assign_name, subscription, %{data: %{deer_table_id: table_id}} = record) do
    # FIXME: adding fields does not work
    changeset = change_record(subscription, record, %{deer_table_id: table_id})

    assign(socket, assign_name, changeset)
  end
end
