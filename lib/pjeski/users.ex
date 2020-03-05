defmodule Pjeski.Users do
  import Ecto.Query, warn: false
  alias Pjeski.Repo

  use Pjeski.DbHelpers.ComposeSearchQuery, [:name, :email]

  alias Pjeski.Users.User

  def list_users("", page, per_page, sort_by) when page > 0 do
    offset = (page - 1) * per_page

    User
    |> sort_users_by(sort_by)
    |> offset(^offset)
    |> limit(^per_page)
    |> Repo.all()
    |> Repo.preload(:subscription)
  end

  def list_users(query_string, page, per_page, sort_by) when page > 0 do
    offset = (page - 1) * per_page

    User
    |> sort_users_by(sort_by)
    |> where(^compose_search_query(query_string))
    |> offset(^offset)
    |> limit(^per_page)
    |> Repo.all()
    |> Repo.preload(:subscription)
  end

  def list_users do
    User
    |> Repo.all()
    |> Repo.preload(:subscription)
  end

  def get_user!(id) do
    User
    |> Repo.get!(id)
    |> Repo.preload(:subscription)
  end

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def admin_create_user(attrs \\ %{}) do
    %User{}
    |> User.admin_changeset(attrs)
    |> Repo.insert()
  end

  def admin_update_user(%User{} = user, attrs) do
    user
    |> User.admin_changeset(attrs)
    |> Repo.update()
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

  defp sort_users_by(q, ""), do: q
  defp sort_users_by(q, "name_desc"), do: q |> order_by(desc: :name)
  defp sort_users_by(q, "name_asc"), do: q |> order_by(asc: :name)
  defp sort_users_by(q, "email_desc"), do: q |> order_by(desc: :email)
  defp sort_users_by(q, "email_asc"), do: q |> order_by(asc: :email)
  defp sort_users_by(q, "locale_desc"), do: q |> order_by(desc: :locale)
  defp sort_users_by(q, "locale_asc"), do: q |> order_by(asc: :locale)
  defp sort_users_by(q, "role_desc"), do: q |> order_by(desc: :role)
  defp sort_users_by(q, "role_asc"), do: q |> order_by(asc: :role)
  defp sort_users_by(q, "admin_notes_desc"), do: q |> order_by(desc: :admin_notes)
  defp sort_users_by(q, "admin_notes_asc"), do: q |> order_by(asc: :admin_notes)
  defp sort_users_by(q, "inserted_at_desc"), do: q |> order_by(desc: :inserted_at)
  defp sort_users_by(q, "inserted_at_asc"), do: q |> order_by(asc: :inserted_at)
  defp sort_users_by(q, "updated_at_desc"), do: q |> order_by(desc: :updated_at)
  defp sort_users_by(q, "updated_at_asc"), do: q |> order_by(asc: :updated_at)

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
