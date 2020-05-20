defmodule PjeskiWeb.DeerRecordsLive.Index do
  use Phoenix.LiveView

  alias PjeskiWeb.Router.Helpers, as: Routes
  import PjeskiWeb.Gettext

  import Pjeski.Users.UserSessionUtils, only: [get_live_user: 2]

  alias Pjeski.Repo
  alias Pjeski.DeerRecords.DeerRecord
  alias Pjeski.UserAvailableSubscriptionLinks.UserAvailableSubscriptionLink

  import Pjeski.DeerRecords, only: [
    change_record: 3,
    create_record: 2,
    delete_record: 2,
    get_record!: 2,
    update_record: 3
  ]

  import Pjeski.DbHelpers.DeerRecordsSearch

  def mount(_params, %{"pjeski_auth" => token, "current_subscription_id" => current_subscription_id} = session, socket) do
    #if connected?(socket), do: :timer.send_interval(30000, self(), :update)
    user = get_live_user(socket, session)

    Gettext.put_locale(user.locale)

    {:ok, assign(socket,
        current_record: nil,
        editing_record: nil,
        new_record: nil,
        page: 1,
        per_page: per_page(),
        token: token,
        current_user: user,
        current_subscription_id: current_subscription_id
      )}
  end

  def render(assigns), do: PjeskiWeb.DeerRecordView.render("index.html", assigns)

  def handle_params(%{"table_id" => table_id} = params, _, %{assigns: %{current_user: user, current_subscription_id: subscription_id}} = socket) do
    query = params["query"]

    case connected?(socket) do
      true ->
        user_subscription_link = Repo.get_by!(UserAvailableSubscriptionLink, [user_id: user.id, subscription_id: subscription_id])
        |> Repo.preload(:subscription)
        subscription = user_subscription_link.subscription
        table_name = table_name_from_subscription(subscription, table_id)

        records = search_records(subscription.id, table_id, query, 1)

        {:noreply,
         socket |> assign(
           count: length(records),
           query: query,
           records: records,
           subscription: subscription,
           table_id: table_id,
           table_name: table_name,
           user_subscription_link: user_subscription_link
         )
        }
      false -> {:noreply, socket |> assign(query: query, records: [], count: 0)}
    end
  end

  def handle_event("close_show", _, socket), do: {:noreply, socket |> assign(current_record: nil)}
  def handle_event("close_new", _, socket), do: {:noreply, socket |> assign(new_record: nil)}
  def handle_event("close_edit", _, socket), do: {:noreply, socket |> assign(editing_record: nil)}

  # FIXME refactor
  def handle_event("validate_edit", %{"deer_record" => attrs}, %{assigns: %{editing_record: record, subscription: subscription, table_id: table_id}} = socket) do
    attrs = Map.merge(attrs, %{"deer_table_id" => table_id}) |> keys_to_atoms

    {:noreply, socket |> assign(editing_record: change_record(subscription, record.data, attrs))}
  end

  def handle_event("save_edit", %{"deer_record" => attrs}, %{assigns: %{editing_record: record, subscription: subscription, table_id: table_id}} = socket) do
    attrs = Map.merge(attrs, %{"deer_table_id" => table_id}) |> keys_to_atoms

    {:ok, _} = update_record(subscription, record.data, attrs)
    # TODO Notify subscribers here

    # waiting for this to get resolved: https://github.com/phoenixframework/phoenix_live_view/issues/340
    patch_to_index(socket |> put_flash(:info, gettext("Record updated successfully.")))
  end

  def handle_event("save_new", %{"deer_record" => attrs}, %{assigns: %{subscription: subscription, table_id: table_id}} = socket) do
    attrs = Map.merge(attrs, %{"deer_table_id" => table_id}) |> keys_to_atoms

    case create_record(subscription, attrs) do
      {:ok, _} ->
        patch_to_index(
          socket
          # waiting for this to get resolved: https://github.com/phoenixframework/phoenix_live_view/issues/340
          |> put_flash(:info, gettext("Record created successfully."))
          |> assign(new_record: nil, query: nil))

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(new_record: changeset)}
    end

  end

  def handle_event("show", %{"record_id" => record_id}, %{assigns: %{records: records, subscription: subscription}} = socket) do
    record = find_record_in_list_or_database(record_id, records, subscription)

    {:noreply, socket |> assign(current_record: record)}
  end

  def handle_event("new", _, %{assigns: %{subscription: %{deer_tables: deer_tables} = subscription, table_id: table_id}} = socket) do
    deer_columns = Enum.find(deer_tables, fn table -> table.id == table_id end).deer_columns
    deer_fields_attrs = Enum.map(deer_columns, fn %{id: column_id} -> %{deer_column_id: column_id, content: ""} end)

    {:noreply, socket |> assign(new_record: change_record(subscription, %DeerRecord{}, %{deer_table_id: table_id, deer_fields: deer_fields_attrs}))}
  end

  def handle_event("edit", %{"record_id" => record_id}, %{assigns: %{records: records, subscription: subscription, table_id: table_id}} = socket) do
    record = find_record_in_list_or_database(record_id, records, subscription)

    {:noreply, socket |> assign(editing_record: change_record(subscription, record, %{deer_table_id: table_id}))}
  end

  def handle_event("delete", %{"record_id" => record_id}, %{assigns: %{records: records, subscription: subscription}} = socket) do
    record = find_record_in_list_or_database(record_id, records, subscription)
    {:ok, _} = delete_record(subscription, record)

    # waiting for this to get resolved: https://github.com/phoenixframework/phoenix_live_view/issues/340
    patch_to_index(socket |> put_flash(:info, gettext("Record deleted successfully.")))
  end

  def handle_event("clear", _, %{assigns: %{table_id: table_id}} = socket) do
    # TODO: refactor when there are records for multiple pages
    {:noreply, push_redirect(socket |> assign(page: 1), to: Routes.live_path(socket, PjeskiWeb.DeerRecordsLive.Index, table_id))}
  end

  def handle_event("filter", %{"query" => query}, %{assigns: %{subscription: subscription, table_id: table_id}} = socket) when byte_size(query) <= 50 do
    records = search_records(subscription.id, table_id, query, 1)

    {:noreply, socket |> assign(records: records, query: query, page: 1, count: length(records))}
  end

  def handle_event("next_page", _, %{assigns: %{page: page}} = socket), do: change_page(page + 1, socket)
  def handle_event("previous_page", _, %{assigns: %{page: page}} = socket), do: change_page(page - 1, socket)

  defp change_page(new_page, %{assigns: %{subscription: subscription, query: query, table_id: table_id}} = socket) do
    records = search_records(subscription.id, table_id, query, new_page)

    {:noreply, socket |> assign(records: records, page: new_page, count: length(records))}
  end

  defp find_record_in_database(id, subscription), do: get_record!(subscription, id)
  defp find_record_in_list_or_database(id, records, subscription) do
    id = id |> String.to_integer

    Enum.find(records, fn record -> record.id == id end) || find_record_in_database(id, subscription)
  end

  defp patch_to_index(%{assigns: %{query: query, table_id: table_id}} = socket) do
    {:noreply,
     push_redirect(assign(socket,
           current_record: nil,
           editing_record: nil,
           page: 1
         ), to: Routes.live_path(socket, PjeskiWeb.DeerRecordsLive.Index, table_id, query: query)
     )}
  end
   
  defp table_name_from_subscription(%{deer_tables: deer_tables}, table_id) do
    %{name: name} = Enum.find(deer_tables, fn deer_table -> deer_table.id == table_id end)

    name
  end

  defp keys_to_atoms(%{} = map) do
    Enum.reduce(map, %{}, fn
    # String.to_existing_atom saves us from overloading the VM by
    # creating too many atoms. It'll always succeed because all the fields
    # in the database already exist as atoms at runtime.
    {key, value}, acc when is_atom(key) -> Map.put(acc, key, value)
      {key, value}, acc when is_binary(key) -> Map.put(acc, String.to_existing_atom(key), value)
    end)
  end
end
