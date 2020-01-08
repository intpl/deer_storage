defmodule PjeskiWeb.Admin.SubscriptionController do
  use PjeskiWeb, :controller
  # TODO: https://hexdocs.pm/phoenix/contexts.html

  alias Pjeski.Subscriptions
  alias Pjeski.Subscriptions.Subscription

  def index(conn, params) do
    query = params["query"] || ""

    per_page = 100
    page = String.to_integer(params["page"] || "1")
    subscriptions = Subscriptions.list_subscriptions(query, page, per_page)

    rendered_pagination = Phoenix.View.render_to_string(
      PjeskiWeb.Admin.SubscriptionView, "_index_pagination.html",
      %{conn: conn, count: length(subscriptions), per_page: per_page, page: page, query: query}
    )

    render(conn, "index.html", subscriptions: subscriptions, page: page, rendered_pagination: rendered_pagination, query: query)
  end

  def new(conn, _params) do
    changeset = Subscriptions.change_subscription(%Subscription{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"subscription" => subscription_params}) do
    case Subscriptions.admin_create_subscription(subscription_params) do
      {:ok, subscription} ->
        conn
        |> put_flash(:info, "Subscription created successfully.")
        |> redirect(to: Routes.admin_subscription_path(conn, :show, subscription))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    subscription = Subscriptions.get_subscription!(id)

    render(conn, "show.html", subscription: subscription, users: subscription.users)
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
        |> put_flash(:info, "Subscription updated successfully.")
        |> redirect(to: Routes.admin_subscription_path(conn, :show, subscription))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", subscription: subscription, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    subscription = Subscriptions.get_subscription!(id)
    {:ok, _subscription} = Subscriptions.delete_subscription(subscription)

    conn
    |> put_flash(:info, "Subscription deleted successfully.")
    |> redirect(to: Routes.admin_subscription_path(conn, :index))
  end
end
