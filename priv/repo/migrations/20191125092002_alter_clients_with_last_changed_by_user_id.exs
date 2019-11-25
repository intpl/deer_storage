defmodule Pjeski.Repo.Migrations.AlterClientsWithLastChangedByUserId do
  use Ecto.Migration

  def change do
    alter table(:clients) do
      add :last_changed_by_user_id, references(:users), on_delete: :nothing
    end
  end
end
