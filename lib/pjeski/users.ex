defmodule Pjeski.Users do
  import Ecto.Query, warn: false
  import Ecto.Changeset, only: [change: 2]
  import Pjeski.DbHelpers.ComposeSearchQuery

  alias Pjeski.Repo
  alias Pjeski.Users.User
  alias Pjeski.UserAvailableSubscriptionLinks.UserAvailableSubscriptionLink

  def notify_subscribers!(event, record) do
    Phoenix.PubSub.broadcast!(Pjeski.PubSub, "Users", {event, record})
  end

  def total_count(), do: Pjeski.Repo.aggregate(User, :count, :id)
  def last_user(), do: from(u in User, limit: 1, order_by: [desc: u.inserted_at]) |> Repo.one

  def list_users("", page, per_page, sort_by) when page > 0 do
    offset = (page - 1) * per_page

    User
    |> sort_users_by(sort_by)
    |> offset(^offset)
    |> limit(^per_page)
    |> Repo.all()
    |> Repo.preload(:last_used_subscription)
  end

  def list_users(query_string, page, per_page, sort_by) when page > 0 do
    offset = (page - 1) * per_page

    User
    |> sort_users_by(sort_by)
    |> where(^compose_search_query([:name, :email, :admin_notes, :time_zone], query_string))
    |> offset(^offset)
    |> limit(^per_page)
    |> Repo.all() |> Repo.preload(:last_used_subscription)
  end

  def list_users do
    User
    |> Repo.all()
    |> Repo.preload(:last_used_subscription)
  end

  def list_users_except_ids(ids) do
    User |> where([u], u.id not in ^ids) |> Repo.all
  end

  def list_users_for_subscription_id_with_permissions(subscription_id) when is_number(subscription_id) do
    from(u in User,
      join: l in UserAvailableSubscriptionLink,
      on: l.subscription_id == ^subscription_id and l.user_id == u.id,
      select: {u, %{subscription_id: l.subscription_id, permission_to_manage_users: l.permission_to_manage_users}},
      order_by: [desc: field(u, :id)]
    ) |> Repo.all
  end

  def get_user!(id) do
    User
    |> Repo.get!(id)
    |> Repo.preload(:last_used_subscription)
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

  def admin_create_user(attrs) do
    case User.admin_changeset(%User{}, attrs) |> Repo.insert() do
      {:ok, user} -> {:ok, user |> maybe_upsert_subscription_link}
      err -> err
    end
  end

  def admin_update_user(%User{} = user, attrs) do
    case User.admin_changeset(user, attrs) |> Repo.update() do
      {:ok, user} -> {:ok, user |> maybe_upsert_subscription_link}
      err -> err
    end
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

  def toggle_permission_for_user_subscription_link!(%UserAvailableSubscriptionLink{} = user_subscription_link, permission_key) do
    previous_value = Map.fetch!(user_subscription_link, permission_key)
    changeset = change(user_subscription_link, %{permission_key => !previous_value})

    Repo.update! changeset
  end

  def update_last_used_subscription_id!(%User{} = user, subscription_id) do
    Repo.update!(change(user, last_used_subscription_id: subscription_id))
    |> Repo.preload(:last_used_subscription)
  end

  def maybe_upsert_subscription_link(%User{id: _user_id, last_used_subscription_id: nil} = user), do: user
  def maybe_upsert_subscription_link(%User{id: user_id, last_used_subscription_id: subscription_id} = user) do
    upsert_subscription_link!(user_id, subscription_id, :nothing)

    user
  end

  def insert_subscription_link_and_maybe_change_last_used_subscription_id(%User{id: user_id, last_used_subscription_id: nil} = user, subscription_id) when is_integer(subscription_id) do
    upsert_subscription_link!(user_id, subscription_id, :raise)

    update_last_used_subscription_id!(user, subscription_id)
  end

  def insert_subscription_link_and_maybe_change_last_used_subscription_id(%User{id: user_id}, subscription_id) when is_integer(subscription_id) do
    upsert_subscription_link!(user_id, subscription_id, :raise)
  end

  def remove_subscription_link_and_maybe_change_last_used_subscription_id(%User{id: user_id, last_used_subscription_id: subscription_id} = user, subscription_id) do
    Repo.transaction(fn ->
      remove_user_subscription_link!(user_id, subscription_id)
      update_last_used_subscription_id!(user, nil)
    end)
  end

  def remove_subscription_link_and_maybe_change_last_used_subscription_id(%User{id: user_id}, subscription_id) when is_number(subscription_id) do
    remove_user_subscription_link!(user_id, subscription_id)
  end

  def upsert_subscription_link!(user_id, subscription_id, on_conflict, attrs \\ %{})do
    %UserAvailableSubscriptionLink{user_id: user_id, subscription_id: subscription_id}
    |> Map.merge(attrs)
    |> Repo.insert!(on_conflict: on_conflict)
  end

  def ensure_user_subscription_link!(user_id, subscription_id, required_permissions \\ []) do
    params = [user_id: user_id, subscription_id: subscription_id] ++ Enum.map(required_permissions, fn k -> {k, true} end)

    Repo.get_by!(UserAvailableSubscriptionLink, params)
  end

  defp remove_user_subscription_link!(user_id, subscription_id) do
    ensure_user_subscription_link!(user_id, subscription_id) |> Repo.delete!
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

  defp sort_users_by(q, "last_used_subscription_name_desc") do
    from u in q,
    left_join: s in assoc(u, :last_used_subscription),
    order_by: [desc: s.name]
  end

  defp sort_users_by(q, "last_used_subscription_name_asc") do
    from u in q,
    left_join: s in assoc(u, :last_used_subscription),
    order_by: [asc: s.name]
  end

  defp sort_users_by(q, "last_used_subscription_expires_on_desc") do
    from u in q,
    left_join: s in assoc(u, :last_used_subscription),
    order_by: [desc: s.expires_on]
  end

  defp sort_users_by(q, "last_used_subscription_expires_on_asc") do
    from u in q,
    left_join: s in assoc(u, :last_used_subscription),
    order_by: [asc: s.expires_on]
  end
end
