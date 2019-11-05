defmodule Pjeski.Users do
  import Ecto.Query, warn: false
  alias Pjeski.Repo

  alias Pjeski.Users.User

  def list_users do
    Repo.all(User)
  end

  def get_user!(id), do: Repo.get!(User, id)

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
end
