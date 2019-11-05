defmodule Pjeski.Repo.Migrations.AlterUsersWithAdminNotes do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :admin_notes, :text
    end
  end
end
