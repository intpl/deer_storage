defmodule Pjeski.Subscriptions do
  import Ecto.Query, warn: false
  alias Pjeski.Repo

  use Pjeski.DbHelpers.ComposeSearchQuery, [:name, :email, :time_zone, :admin_notes]

  alias Pjeski.Subscriptions.Subscription

  def list_subscriptions("", page, per_page, sort_by) when page > 0 do
    offset = (page - 1) * per_page

    Subscription
    |> sort_subscriptions_by(sort_by)
    |> offset(^offset)
    |> limit(^per_page)
    |> Repo.all
    |> Repo.preload(:users)
  end

  def list_subscriptions(query_string, page, per_page, sort_by) when page > 0 do
    offset = (page - 1) * per_page

    Subscription
    |> sort_subscriptions_by(sort_by)
    |> where(^compose_search_query(query_string))
    |> offset(^offset)
    |> limit(^per_page)
    |> Repo.all
    |> Repo.preload(:users)
  end

  def list_subscriptions do
    Subscription
    |> Repo.all
    |> Repo.preload(:users)
  end

  def list_expired_subscriptions do
    # todo: honor subscription time zone
    date = Date.utc_today
    query = from s in Subscription, where: fragment("?::date", s.expires_on) <= ^date

    query
    |> Repo.all
    |> Repo.preload(:users)
  end

  def get_subscription!(id) do
    Subscription
    |> Repo.get!(id)
    |> Repo.preload(:users)
  end

  def admin_create_subscription(attrs \\ %{}) do
    %Subscription{}
    |> Subscription.admin_changeset(attrs)
    |> Repo.insert()
  end

  def create_subscription(attrs \\ %{}) do
    %Subscription{}
    |> Subscription.changeset(attrs)
    |> Repo.insert()
  end

  def admin_update_subscription(%Subscription{} = subscription, attrs) do
    subscription
    |> Subscription.admin_changeset(attrs)
    |> Repo.update()
  end

  def update_subscription(%Subscription{} = subscription, attrs) do
    subscription
    |> Subscription.changeset(attrs)
    |> Repo.update()
  end

  def delete_subscription(%Subscription{} = subscription) do
    Repo.delete(subscription)
  end

  def change_subscription(%Subscription{} = subscription) do
    Subscription.changeset(subscription, %{})
  end

  def admin_change_subscription(%Subscription{} = subscription) do
    Subscription.admin_changeset(subscription, %{})
  end

  defp sort_subscriptions_by(q, ""), do: q
  defp sort_subscriptions_by(q, "name_desc"), do: q |> order_by(desc: :name)
  defp sort_subscriptions_by(q, "name_asc"), do: q |> order_by(asc: :name)
  defp sort_subscriptions_by(q, "email_desc"), do: q |> order_by(desc: :email)
  defp sort_subscriptions_by(q, "email_asc"), do: q |> order_by(asc: :email)
  defp sort_subscriptions_by(q, "time_zone_desc"), do: q |> order_by(desc: :time_zone)
  defp sort_subscriptions_by(q, "time_zone_asc"), do: q |> order_by(asc: :time_zone)
  defp sort_subscriptions_by(q, "expires_on_desc"), do: q |> order_by(desc: :expires_on)
  defp sort_subscriptions_by(q, "expires_on_asc"), do: q |> order_by(asc: :expires_on)
  defp sort_subscriptions_by(q, "admin_notes_desc"), do: q |> order_by(desc: :admin_notes)
  defp sort_subscriptions_by(q, "admin_notes_asc"), do: q |> order_by(asc: :admin_notes)
  defp sort_subscriptions_by(q, "inserted_at_desc"), do: q |> order_by(desc: :inserted_at)
  defp sort_subscriptions_by(q, "inserted_at_asc"), do: q |> order_by(asc: :inserted_at)
  defp sort_subscriptions_by(q, "updated_at_desc"), do: q |> order_by(desc: :updated_at)
  defp sort_subscriptions_by(q, "updated_at_asc"), do: q |> order_by(asc: :updated_at)

  defp sort_subscriptions_by(q, "users_count_desc") do
    from s in q,
    left_join: u in assoc(s, :users),
    order_by: [asc: count(u.id)],
    group_by: s.id
  end

  defp sort_subscriptions_by(q, "users_count_asc") do
    from s in q,
    left_join: u in assoc(s, :users),
    order_by: [desc: count(u.id)],
    group_by: s.id
  end
end
