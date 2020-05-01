defmodule Pjeski.Users do
  import Ecto.Query, warn: false
  import Ecto.Changeset, only: [change: 2]

  alias Pjeski.Repo
  alias Pjeski.Subscriptions

  import Pjeski.DbHelpers.ComposeSearchQuery

  alias Pjeski.Users.User
  alias Pjeski.Subscriptions.Subscription
  alias Pjeski.UserAvailableSubscriptionLinks.UserAvailableSubscriptionLink

  def notify_subscribers!(event, result) do
    Phoenix.PubSub.broadcast!(Pjeski.PubSub, "Users", {event, result})
  end

  def total_count(), do: Pjeski.Repo.aggregate(User, :count, :id)
  def last_user(), do: from(u in User, limit: 1, order_by: [desc: u.inserted_at]) |> Repo.one

  def list_users("", page, per_page, sort_by, _search_by) when page > 0 do
    offset = (page - 1) * per_page

    User
    |> sort_users_by(sort_by)
    |> offset(^offset)
    |> limit(^per_page)
    |> Repo.all()
    |> Repo.preload(:subscription)
  end

  def list_users(query_string, page, per_page, sort_by, search_by) when page > 0 do
    offset = (page - 1) * per_page
    query = User
    |> sort_users_by(sort_by)
    |> where(^compose_search_query([:name, :email, :admin_notes, :time_zone], query_string))
    |> offset(^offset)
    |> limit(^per_page)

    query = case search_by do
              "users" -> query
              "subscriptions_and_users" ->
                subscriptions_ids = Subscription
                |> where(^compose_search_query([:name, :admin_notes], query_string))
                |> select([:id])
                |> Repo.all()
                |> Enum.map(fn s -> s.id end)

                query |> or_where([u], u.subscription_id in ^subscriptions_ids)
            end


    query |> Repo.all() |> Repo.preload(:subscription)
  end

  def list_users do
    User
    |> Repo.all()
    |> Repo.preload(:subscription)
  end

  def list_users_for_subscription_id(subscription_id) when is_number(subscription_id) do
    Subscriptions.get_subscription!(subscription_id).users
  end

  def get_user!(id) do
    User
    |> Repo.get!(id)
    |> Repo.preload(:subscription)
  end

  def create_user(attrs \\ %{}) do
    user = %User{}
    |> User.changeset(attrs)
    |> Repo.insert!()
    |> maybe_upsert_subscription_link

    {:ok, user}
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def admin_create_user(attrs \\ %{}) do
    user = %User{}
    |> User.admin_changeset(attrs)
    |> Repo.insert!()
    |> maybe_upsert_subscription_link

    {:ok, user}
  end

  def admin_update_user(%User{} = user, attrs) do
    user = user
    |> User.admin_changeset(attrs)
    |> Repo.update!()
    |> maybe_upsert_subscription_link

    {:ok, user}
  end

  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end

  def toggle_admin(%User{} = user) do
    role = case user.role do
             "user" -> "admin"
             "admin" -> "user"
           end

    user
    |> User.changeset_role(%{role: role})
    |> Repo.update()
  end

  def update_subscription_id!(%User{} = user, subscription_id) do
    case Repo.update!(change(user, subscription_id: subscription_id)) do
      %{subscription_id: nil} = user -> Map.merge(user, %{subscription: nil})
      user -> user |> Repo.preload(:subscription)
    end
  end

  def maybe_upsert_subscription_link(%User{id: _user_id, subscription_id: nil} = user), do: user
  def maybe_upsert_subscription_link(%User{id: user_id, subscription_id: subscription_id} = user) do
    upsert_subscription_link!(user_id, subscription_id, :nothing)

    user
  end

  def insert_subscription_link_and_maybe_change_id(%User{id: user_id, subscription_id: nil} = user, subscription_id) when is_integer(subscription_id) do
    upsert_subscription_link!(user_id, subscription_id, :raise)

    update_subscription_id!(user, subscription_id)
  end

  def insert_subscription_link_and_maybe_change_id(%User{id: user_id}, subscription_id) when is_integer(subscription_id) do
    upsert_subscription_link!(user_id, subscription_id, :raise)
  end

  def remove_subscription_link_and_maybe_change_id(%User{id: user_id, subscription_id: subscription_id} = user, subscription_id) do
    # TODO: find another subscription from available_subscriptions and assign it's id to the user

    Repo.transaction(fn ->
      remove_user_subscription_link(user_id, subscription_id)
      update_subscription_id!(user, nil)
    end)
  end

  def remove_subscription_link_and_maybe_change_id(%User{id: user_id}, subscription_id) when is_number(subscription_id) do
    remove_user_subscription_link(user_id, subscription_id)
  end

  def upsert_subscription_link!(user_id, subscription_id, on_conflict) do
    Repo.insert(
      %UserAvailableSubscriptionLink{
        user_id: user_id,
        subscription_id: subscription_id
      },
      on_conflict: on_conflict
    )
  end

  defp remove_user_subscription_link(user_id, subscription_id) do
    Repo.get_by!(UserAvailableSubscriptionLink, [user_id: user_id, subscription_id: subscription_id])
    |> Repo.delete!
  end

  defp sort_users_by(q, ""), do: q
  defp sort_users_by(q, "name_desc"), do: q |> order_by(desc: :name)
  defp sort_users_by(q, "name_asc"), do: q |> order_by(asc: :name)
  defp sort_users_by(q, "email_desc"), do: q |> order_by(desc: :email)
  defp sort_users_by(q, "email_asc"), do: q |> order_by(asc: :email)
  defp sort_users_by(q, "locale_desc"), do: q |> order_by(desc: :locale)
  defp sort_users_by(q, "locale_asc"), do: q |> order_by(asc: :locale)
  defp sort_users_by(q, "role_desc"), do: q |> order_by(desc: :role)
  defp sort_users_by(q, "role_asc"), do: q |> order_by(asc: :role)
  defp sort_users_by(q, "time_zone_desc"), do: q |> order_by(desc: :time_zone)
  defp sort_users_by(q, "time_zone_asc"), do: q |> order_by(asc: :time_zone)
  defp sort_users_by(q, "admin_notes_desc"), do: q |> order_by(desc_nulls_last: :admin_notes)
  defp sort_users_by(q, "admin_notes_asc"), do: q |> order_by(asc_nulls_first: :admin_notes)
  defp sort_users_by(q, "inserted_at_desc"), do: q |> order_by(desc: :inserted_at)
  defp sort_users_by(q, "inserted_at_asc"), do: q |> order_by(asc: :inserted_at)
  defp sort_users_by(q, "updated_at_desc"), do: q |> order_by(desc: :updated_at)
  defp sort_users_by(q, "updated_at_asc"), do: q |> order_by(asc: :updated_at)
  defp sort_users_by(q, "email_confirmed_at_desc"), do: q |> order_by(desc_nulls_last: :email_confirmed_at)
  defp sort_users_by(q, "email_confirmed_at_asc"), do: q |> order_by(asc_nulls_first: :email_confirmed_at)

  defp sort_users_by(q, "subscription_name_desc") do
    from u in q,
    left_join: s in assoc(u, :subscription),
    order_by: [desc: s.name]
  end

  defp sort_users_by(q, "subscription_name_asc") do
    from u in q,
    left_join: s in assoc(u, :subscription),
    order_by: [asc: s.name]
  end

  defp sort_users_by(q, "subscription_expires_on_desc") do
    from u in q,
    left_join: s in assoc(u, :subscription),
    order_by: [desc: s.expires_on]
  end

  defp sort_users_by(q, "subscription_expires_on_asc") do
    from u in q,
    left_join: s in assoc(u, :subscription),
    order_by: [asc: s.expires_on]
  end
end
