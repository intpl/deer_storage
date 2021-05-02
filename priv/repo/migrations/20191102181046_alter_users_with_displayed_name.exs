defmodule DeerStorage.Repo.Migrations.AlterUsersWithDisplayedName do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :displayed_name, :string
    end
  end
end
