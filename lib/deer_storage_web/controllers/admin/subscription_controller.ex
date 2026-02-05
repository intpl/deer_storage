defmodule DeerStorageWeb.Admin.SubscriptionController do
  use DeerStorageWeb, :controller
  # TODO: https://hexdocs.pm/phoenix/contexts.html

  alias DeerStorage.Subscriptions
  alias DeerStorage.Subscriptions.Subscription

  def search(conn, params) do
    query = params["query"] || ""

    subscriptions =
      Subscriptions.list_subscriptions(query, 1, 100, "")
      |> Enum.map(fn subscription -> %{id: subscription.id, text: subscription.name} end)

    json(conn, subscriptions)
  end

  def index(conn, params) do
    query = params["query"] || ""
    sort_by = params["sort_by"] || ""

    per_page = 50
    page = String.to_integer(params["page"] || "1")
    subscriptions = Subscriptions.list_subscriptions(query, page, per_page, sort_by)

    rendered_pagination =
      Phoenix.View.render_to_string(
        DeerStorageWeb.Admin.SubscriptionView,
        "_index_pagination.html",
        %{
          conn: conn,
          count: length(subscriptions),
          per_page: per_page,
          page: page,
          query: query,
          sort_by: sort_by
        }
      )

    render(
      conn,
      "index.html",
      subscriptions: subscriptions,
      page: page,
      rendered_pagination: rendered_pagination,
      query: query,
      sort_by: sort_by
    )
  end

  def new(conn, _params) do
    changeset = Subscriptions.change_subscription(%Subscription{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"subscription" => subscription_params}) do
    case Subscriptions.admin_create_subscription(subscription_params) do
      {:ok, subscription} ->
        conn
        |> put_flash(:info, "Database created successfully.")
        |> redirect(to: Routes.admin_subscription_path(conn, :show, subscription))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    subscription = Subscriptions.get_subscription!(id)
    subscription_users = subscription.users

    excluded_users_ids =
      subscription_users
      |> Enum.map(fn u -> u.id end)
      |> Poison.encode!()

    {uploaded_files_count, used_storage_kilobytes} =
      DeerCache.SubscriptionStorageCache.fetch_data(subscription.id)

    render(
      conn,
      "show.html",
      subscription: subscription,
      users: subscription_users,
      excluded_users_ids: excluded_users_ids,
      used_storage_megabytes: Float.ceil(used_storage_kilobytes / 1024, 2),
      uploaded_files_count: uploaded_files_count
    )
  end

  def edit(conn, %{"id" => id}) do
    subscription = Subscriptions.get_subscription!(id)
    changeset = Subscriptions.admin_change_subscription(subscription)
    render(conn, "edit.html", subscription: subscription, changeset: changeset)
  end

  def update(conn, %{"id" => id, "subscription" => subscription_params}) do
    subscription = Subscriptions.get_subscription!(id)

    case Subscriptions.admin_update_subscription(subscription, subscription_params) do
      {:ok, subscription} ->
        conn
        |> put_flash(:info, "Database updated successfully.")
        |> redirect(to: Routes.admin_subscription_path(conn, :show, subscription))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", subscription: subscription, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    subscription = Subscriptions.get_subscription!(id)
    {:ok, _subscription} = Subscriptions.delete_subscription(subscription)

    conn
    |> put_flash(:info, "Database deleted successfully.")
    |> redirect(to: Routes.admin_subscription_path(conn, :index))
  end
end
